const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

const SECRET_PATH = path.join(__dirname, 'client_secret.json');
const CHANNELS_PATH = path.join(__dirname, 'accounts/channels.json');

const secret = JSON.parse(fs.readFileSync(SECRET_PATH));
const { client_id, client_secret } = secret.installed;
const { accounts } = JSON.parse(fs.readFileSync(CHANNELS_PATH));

async function getChannelByHandle(yt, handle) {
  try {
    const res = await yt.channels.list({
      part: ['snippet', 'statistics'],
      forHandle: handle.replace('@', '')
    });
    return res.data.items?.[0] || null;
  } catch (e) { return null; }
}

async function getChannelStats(oauth2) {
  const yt = google.youtube({ version: 'v3', auth: oauth2 });
  const mine = await yt.channels.list({ part: ['snippet', 'statistics'], mine: true, maxResults: 50 });
  return mine.data.items || [];
}

async function report() {
  console.log('\n==============================');
  console.log('   DTSLIB YouTube 전채널 현황');
  console.log('==============================\n');

  for (const account of accounts) {
    const tokenPath = path.join(__dirname, account.token_file);

    if (!fs.existsSync(tokenPath)) {
      console.log(`[${account.email}]`);
      console.log(`  ⚠ 토큰 없음 → node auth.cjs ${account.id.slice(-1)} 실행 필요\n`);
      continue;
    }

    const tokens = JSON.parse(fs.readFileSync(tokenPath));
    const oauth2 = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3000/callback');
    oauth2.setCredentials(tokens);

    // 토큰 갱신 자동 저장
    oauth2.on('tokens', (newTokens) => {
      const updated = { ...tokens, ...newTokens };
      fs.writeFileSync(tokenPath, JSON.stringify(updated, null, 2));
    });

    const yt = google.youtube({ version: 'v3', auth: oauth2 });
    console.log(`[${account.email}] — ${account.channels.length}개 채널`);

    for (const ch of account.channels) {
      try {
        const data = await getChannelByHandle(yt, ch.handle);
        if (!data) {
          console.log(`  ${ch.handle}  ⚠ 채널 없음`);
          continue;
        }
        const s = data.statistics;
        const name = data.snippet.title;
        const subs = parseInt(s.subscriberCount || 0).toLocaleString();
        const views = parseInt(s.viewCount || 0).toLocaleString();
        const videos = s.videoCount || 0;
        console.log(`  ${name} (${ch.handle})`);
        console.log(`    구독 ${subs} | 조회 ${views} | 영상 ${videos}개`);
      } catch (e) {
        console.log(`  ${ch.handle}  ⚠ 오류: ${e.message}`);
      }
    }
    console.log('');
  }

  console.log('==============================\n');
}

report().catch(console.error);
