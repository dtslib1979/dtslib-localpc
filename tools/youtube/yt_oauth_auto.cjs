/**
 * yt_oauth_auto.cjs — YouTube OAuth 완전 자동화
 * Chrome 킬 → launchPersistentContext(실제 프로필) → 로그인 → Allow
 * dimas.thomas.sancho@gmail.com (Account A)
 */
'use strict';

const { chromium } = require('playwright');
const { google }   = require('googleapis');
const http  = require('http');
const url   = require('url');
const fs    = require('fs');
const path  = require('path');

const __dir       = __dirname;
const SECRET_PATH = path.join(__dir, 'client_secret.json');
const TOKEN_PATH  = path.join(__dir, 'accounts', 'token_a.json');

const SCOPES = [
  'https://www.googleapis.com/auth/youtube',
  'https://www.googleapis.com/auth/yt-analytics.readonly',
  'https://www.googleapis.com/auth/spreadsheets',
  'https://www.googleapis.com/auth/drive.file'
];

const ACCOUNT_EMAIL = 'dimas.thomas.sancho@gmail.com';
const PASSWORD      = 'Think4good*';

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function startCallbackServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const qs = url.parse(req.url, true).query;
      if (qs.code) {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end('<h1>✅ 인증 완료.</h1>');
        server.close();
        resolve(qs.code);
      } else {
        res.end('waiting...');
      }
    });
    server.listen(3000, '0.0.0.0', () => console.log('  localhost:3000 대기 중...'));
    server.on('error', (e) => { console.log('  포트 오류:', e.message); resolve(null); });
  });
}

(async () => {
  const secret = JSON.parse(fs.readFileSync(SECRET_PATH));
  const { client_id, client_secret } = secret.installed;
  const oauth2 = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3000/callback');

  const authUrl = oauth2.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
    login_hint: ACCOUNT_EMAIL,
    prompt: 'consent',
  });

  console.log(`\n[Account A] ${ACCOUNT_EMAIL}`);

  // 1. callback 서버 시작
  const codePromise = startCallbackServer();

  // 2. Chrome 실행 (login.cjs 패턴: channel:'chrome' + 커스텀 프로필)
  console.log('Chrome 실행 중...');
  const profDir = path.join(require('os').homedir(), '.dtslib-youtube-profiles', 'account_a');
  fs.mkdirSync(profDir, { recursive: true });
  const ctx = await chromium.launchPersistentContext(profDir, {
    channel: 'chrome',
    headless: false,
    viewport: { width: 1280, height: 900 },
    args: ['--no-first-run', '--no-default-browser-check', '--disable-blink-features=AutomationControlled'],
    ignoreDefaultArgs: ['--enable-automation', '--disable-infobars'],
    ignoreHTTPSErrors: true,
    timeout: 30000,
  });

  await ctx.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => false });
    delete window.__playwright;
  });

  const page = await ctx.newPage();
  console.log('OAuth URL 이동...');
  await page.goto(authUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await sleep(2000);

  console.log('페이지:', await page.title());

  // 3. 계정 선택 화면
  const acctBtn = await page.$(`[data-email="${ACCOUNT_EMAIL}"]`).catch(() => null)
    || await page.$(`[data-identifier="${ACCOUNT_EMAIL}"]`).catch(() => null);
  if (acctBtn) {
    console.log('계정 선택 화면 — 클릭');
    await acctBtn.click();
    await sleep(3000);
  }

  // 4. 로그인 화면 처리
  const body1 = await page.innerText('body').catch(() => '');
  if (body1.includes('로그인할 수 없음') || body1.includes('can\'t sign in') || body1.includes('not be secure')) {
    console.log('⚠️ Google이 브라우저 차단. 이메일/비번 직접 입력 시도...');
    // "다른 계정으로 로그인" 링크 클릭
    const altLink = await page.$('a[href*="accounts.google.com"]').catch(() => null)
      || await page.$('a:has-text("다른 계정")').catch(() => null)
      || await page.$('a:has-text("다른 방법")').catch(() => null);
    if (altLink) { await altLink.click(); await sleep(2000); }
  }

  // 계정 선택 후 이메일 입력 화면이 실제로 뜨는지 확인 (이미 로그인된 계정은 동의 화면으로 바로 진행)
  const emailInput = await page.$('input[type="email"], input#identifierId').catch(() => null);
  const emailVisible = emailInput ? await emailInput.isVisible().catch(() => false) : false;

  if (emailVisible) {
    console.log('이메일 입력...');
    await emailInput.fill(ACCOUNT_EMAIL);
    await page.keyboard.press('Enter');
    await sleep(3000);
    const body3 = await page.innerText('body').catch(() => '');
    if (body3.includes('비밀번호') || body3.includes('password') || body3.includes('Password')) {
      console.log('비밀번호 입력...');
      const pwInput = await page.$('input[type="password"]').catch(() => null);
      if (pwInput) {
        await pwInput.fill(PASSWORD);
        await page.keyboard.press('Enter');
        await sleep(5000);
      }
    }
  } else {
    console.log('이메일 입력 화면 없음 — 동의/경고 화면으로 직행');
  }

  // 5. Allow/허용 버튼 대기 + 클릭
  console.log('Allow 버튼 대기...');
  for (let i = 0; i < 30; i++) {
    const pageText = await page.innerText('body').catch(() => '');
    const btns = await page.$$eval('button', bs => bs.map(b => b.innerText.trim()).filter(t => t)).catch(() => []);
    const currentUrlNow = page.url();
    console.log(`  [${i+1}] URL: ${currentUrlNow.substring(0,80)} | 버튼: ${JSON.stringify(btns)}`);
    // 스크린샷 (처음 3회만)
    if (i < 3) { await page.screenshot({ path: `/tmp/oauth_step_${i+1}.png` }).catch(() => {}); }

    // callback URL 도달 = 코드 수신 완료 → 즉시 루프 탈출
    if (currentUrlNow.includes('localhost:3000/callback') || currentUrlNow.includes('127.0.0.1:3000/callback')) {
      console.log('  ✅ callback URL 감지 — 루프 종료');
      break;
    }

    // 최종 허용 버튼 (OAuth consent 완료)
    const finalAllowBtn =
      await page.$('button:has-text("허용")').catch(() => null) ||
      await page.$('button:has-text("Allow")').catch(() => null);

    if (finalAllowBtn) {
      console.log('  ✅ 최종 Allow 버튼 — 클릭!');
      await finalAllowBtn.click();
      await sleep(3000);
      break;
    }

    // 브랜드/계정 선택 화면 처리 (YouTube OAuth 중간 계정 선택)
    if (pageText.includes('계정 또는 브랜드 계정 선택') || pageText.includes('Select an account')) {
      console.log('  📋 브랜드 계정 선택 화면 — 메인 계정 클릭...');
      // dimas.thomas.sancho@gmail.com 항목 또는 첫 번째 항목 클릭
      const brandAcct =
        await page.$(`[data-email="${ACCOUNT_EMAIL}"]`).catch(() => null) ||
        await page.$(`li:has-text("${ACCOUNT_EMAIL}")`).catch(() => null) ||
        await page.evaluate((email) => {
          const all = document.querySelectorAll('li, [role="listitem"], div.account-chooser-item, div[data-authuser]');
          for (const el of all) {
            if (el.innerText && el.innerText.includes(email)) return el;
          }
          // fallback: 첫 번째 항목
          const first = document.querySelector('ul li:first-child, [role="list"] [role="listitem"]:first-child');
          return first || null;
        }, ACCOUNT_EMAIL).catch(() => null);
      if (brandAcct) {
        await page.evaluate(el => el.click(), brandAcct).catch(async () => {
          await brandAcct.click({ force: true }).catch(() => {});
        });
        await sleep(3000);
        continue;
      }
    }

    // consentsummary 페이지: 체크박스 먼저 선택
    if (currentUrlNow.includes('/consentsummary')) {
      // "액세스를 허용하지 않음" 다이얼로그가 떠있으면 "돌아가기" 클릭
      const denyDialog = await page.$('button:has-text("돌아가기")').catch(() => null);
      if (denyDialog && btns.includes('돌아가기')) {
        console.log('  ⚠️ 거부 다이얼로그 감지 — 돌아가기 클릭');
        await denyDialog.click({ force: true }).catch(() => {});
        await sleep(2000);
      }
      // 모두 선택 체크박스 클릭
      const selectAll = await page.$('input[type="checkbox"]').catch(() => null);
      if (selectAll) {
        const checked = await selectAll.isChecked().catch(() => false);
        if (!checked) {
          console.log('  ☑️ 모두 선택 체크박스 클릭...');
          await selectAll.click({ force: true }).catch(async () => {
            await page.evaluate(() => {
              const cb = document.querySelector('input[type="checkbox"]');
              if (cb) cb.click();
            });
          });
          await sleep(1500);
        }
      }
    }

    // /signin/oauth/warning 페이지 전용 핸들러 (미인증앱 경고)
    // 흐름: "고급" 클릭 → 숨겨진 "계속" 링크 노출 → 클릭
    const currentUrl = page.url();
    if (currentUrl.includes('/signin/oauth/warning') || currentUrl.includes('/oauth/warning')
        || pageText.includes('Google에서 확인하지 않은 앱') || pageText.includes('unverified app')) {
      console.log('  ⚠️ warning 페이지 감지 — 고급 → 계속 시도...');

      // Step 1: "계속" 이미 보이면 바로 클릭
      let contVisible = await page.$('a:has-text("계속"), button:has-text("계속")').catch(() => null);
      if (!contVisible) {
        // Step 2: "고급" 버튼 클릭하여 숨겨진 링크 노출
        const advBtn =
          await page.$('a:has-text("고급")').catch(() => null) ||
          await page.$('button:has-text("고급")').catch(() => null) ||
          await page.$('[jsname="ozardib"]').catch(() => null) ||
          await page.evaluate(() => {
            const all = document.querySelectorAll('a, button, [role="button"]');
            return [...all].find(e => e.innerText && (e.innerText.trim() === '고급' || e.innerText.includes('Advanced'))) || null;
          }).catch(() => null);
        if (advBtn) {
          console.log('  🔽 고급 클릭...');
          await page.evaluate(el => el.click(), advBtn).catch(() => advBtn.click({ force: true }).catch(() => {}));
          await sleep(1500);
        }
      }

      // Step 3: "계속" 링크 클릭 (고급 클릭 후 나타남)
      const clicked = await page.evaluate(() => {
        const all = document.querySelectorAll('a, button, [role="button"], span');
        for (const el of all) {
          const t = el.innerText && el.innerText.trim();
          if (t && (t === '계속' || t.startsWith('계속') || t === 'Continue' || t.includes('(안전하지 않음)'))) {
            el.click();
            return t;
          }
        }
        return null;
      }).catch(() => null);
      if (clicked) {
        console.log(`  ✅ warning 계속 클릭: "${clicked}"`);
        await sleep(3000);
        continue;
      }
      console.log('  ❌ 계속 버튼 못 찾음 — 스크린샷 저장');
      await page.screenshot({ path: '/tmp/warning_page.png' });
    }

    // 중간 단계 버튼 (계속/Continue — 미인증앱 경고, 스코프 확인 등)
    // consentsummary: 다이얼로그 없을 때 첫 번째 "계속", 그외 첫 번째 "계속"
    const contBtns = await page.$$('button:has-text("계속")').catch(() => []);
    const contBtnEN = await page.$$('button:has-text("Continue")').catch(() => []);
    const allContBtns = [...contBtns, ...contBtnEN];
    // 다이얼로그의 "계속" 버튼(거부 확인)을 피하기 위해 첫 번째 "계속" 사용
    const contBtn = allContBtns.length > 0 ? allContBtns[0]
      : await page.$('[jsname="b3VHJd"]').catch(() => null);

    if (contBtn) {
      console.log(`  ➡️ 중간 버튼 클릭 (${allContBtns.length}개 중 마지막)...`);
      // force:true로 overlay 우회
      try {
        await contBtn.click({ force: true, timeout: 5000 });
      } catch (e) {
        console.log('  ⚠️ force 클릭도 실패, mouse.click 시도...');
        try {
          const box = await contBtn.boundingBox();
          if (box) {
            await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
          }
        } catch (e2) {
          console.log('  ❌ 모든 클릭 방법 실패');
        }
      }
      await sleep(3000);
      continue;
    }

    // 2FA 대기
    if (pageText.includes('2단계 인증') || pageText.includes('2-Step') || pageText.includes('본인 확인')) {
      console.log('  📱 2FA 대기 중 — 핸드폰에서 승인해주세요...');
      await sleep(8000);
      continue;
    }

    // 비밀번호 입력 처리
    if (pageText.includes('비밀번호') || pageText.includes('password') || pageText.includes('Password')) {
      const pwInput = await page.$('input[type="password"]').catch(() => null);
      if (pwInput) {
        console.log('  비밀번호 입력...');
        await pwInput.fill(PASSWORD);
        await page.keyboard.press('Enter');
        await sleep(5000);
        continue;
      }
    }

    // 2FA 또는 "계속" 버튼
    const clicked = await page.click('#identifierNext, #passwordNext', { timeout: 3000 }).then(() => true).catch(() => false);
    if (clicked) { await sleep(3000); continue; }

    await sleep(5000);
  }

  // 6. code 수신 대기 (최대 120초)
  console.log('\n인증 코드 대기 중...');
  const code = await Promise.race([
    codePromise,
    sleep(120000).then(() => null),
  ]);

  await ctx.close();

  if (!code) {
    console.log('❌ 코드 수신 실패');
    process.exit(1);
  }

  console.log('코드 수신:', code.substring(0, 20) + '...');

  const { tokens } = await oauth2.getToken(code);
  oauth2.setCredentials(tokens);

  fs.mkdirSync(path.dirname(TOKEN_PATH), { recursive: true });
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(tokens, null, 2));
  console.log('\n✅ token_a.json 저장 완료');
  console.log('  refresh_token:', tokens.refresh_token ? '있음 ✅' : '없음 ⚠️');

  try {
    const yt = google.youtube({ version: 'v3', auth: oauth2 });
    const res = await yt.channels.list({ part: ['snippet'], mine: true });
    const ch = res.data.items?.[0];
    console.log('✅ 채널:', ch?.snippet?.title || '(채널 없음)');
  } catch (e) {
    console.log('⚠️ YouTube API 검증 실패 (스코프 미포함):', e.message);
    console.log('   → GCP console에서 YouTube Data API v3 활성화 후 재실행 필요');
    console.log('   → token_a.json은 저장됨 (refresh_token 있음)');
  }

  process.exit(0);
})();
