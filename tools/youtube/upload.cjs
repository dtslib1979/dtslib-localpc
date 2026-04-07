/**
 * upload.cjs — YouTube 동영상 업로드 v1.0
 *
 * - OAuth 토큰 기반 (auth.cjs로 사전 발급 필요)
 * - uploads/*.json 스펙 파일 읽기
 * - 업로드 완료 시 uploads/done/ 이동
 *
 * 사용법:
 *   node upload.cjs [계정id]           # uploads/*.json 전체 처리
 *   node upload.cjs [계정id] [파일명]  # 특정 파일만
 *
 * 예: node upload.cjs b
 *     node upload.cjs b my-video.json
 *
 * 업로드 스펙 JSON 형식:
 * {
 *   "account": "b",
 *   "title": "영상 제목",
 *   "description": "설명",
 *   "tags": ["태그1", "태그2"],
 *   "category_id": "22",         // 22=People&Blogs, 27=Education, 10=Music
 *   "privacy": "private",        // private | public | unlisted
 *   "file": "D:/path/to/video.mp4",
 *   "thumbnail": "D:/path/to/thumb.jpg"  // 선택
 * }
 */

'use strict';

const { google } = require('googleapis');
const fs   = require('fs');
const path = require('path');

const __dir       = __dirname;
const SECRET_PATH = path.join(__dir, 'client_secret.json');
const UPLOADS_DIR = path.join(__dir, 'uploads');

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

const ACCOUNT_MAP = {
  a: { email: 'dimas.thomas.sancho@gmail.com', token: 'accounts/token_a.json' },
  b: { email: 'dtslib1979@gmail.com',          token: 'accounts/token_b.json' },
  c: { email: 'Thomas.tj.Park@gmail.com',      token: 'accounts/token_c.json' },
  d: { email: 'dimas@dtslib.com',              token: 'accounts/token_d.json' }
};

const accountId = process.argv[2];
const uploadFile = process.argv[3];

if (!accountId || !ACCOUNT_MAP[accountId]) {
  console.log('사용법: node upload.cjs [a|b|c|d] [파일명(선택)]');
  console.log('  a = dimas.thomas.sancho@ (parksy)');
  console.log('  b = dtslib1979@ (branch hub)');
  console.log('  c = Thomas.tj.Park@ (EAE)');
  console.log('  d = dimas@dtslib.com (HQ)');
  process.exit(1);
}

const account = ACCOUNT_MAP[accountId];
const TOKEN_PATH = path.join(__dir, account.token);

if (!fs.existsSync(TOKEN_PATH)) {
  console.log(`토큰 없음: ${TOKEN_PATH}`);
  console.log(`먼저 실행: node auth.cjs ${accountId}`);
  process.exit(1);
}

// 처리할 업로드 파일 목록
fs.mkdirSync(UPLOADS_DIR, { recursive: true });
let uploadFiles;
if (uploadFile) {
  uploadFiles = [path.join(UPLOADS_DIR, uploadFile)];
} else {
  uploadFiles = (fs.readdirSync(UPLOADS_DIR).catch?.() || fs.readdirSync(UPLOADS_DIR))
    .filter(f => f.endsWith('.json'))
    .map(f => path.join(UPLOADS_DIR, f));
}

if (!uploadFiles.length) {
  console.log('uploads/ 에 JSON 스펙 파일 없음');
  process.exit(0);
}

// ─── OAuth2 클라이언트 ──────────────────────────────────────────
const secret = JSON.parse(fs.readFileSync(SECRET_PATH));
const { client_id, client_secret } = secret.installed;
const oauth2 = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3000/callback');

const tokens = JSON.parse(fs.readFileSync(TOKEN_PATH));
oauth2.setCredentials(tokens);
oauth2.on('tokens', (newTokens) => {
  const updated = { ...tokens, ...newTokens };
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(updated, null, 2));
});

// ─── 업로드 ─────────────────────────────────────────────────────
async function uploadVideo(spec) {
  if (!fs.existsSync(spec.file)) {
    console.log(`  ❌ 파일 없음: ${spec.file}`);
    return false;
  }

  const yt = google.youtube({ version: 'v3', auth: oauth2 });
  const fileSize = fs.statSync(spec.file).size;
  const fileSizeMB = (fileSize / 1024 / 1024).toFixed(1);
  console.log(`  파일: ${path.basename(spec.file)} (${fileSizeMB} MB)`);

  const res = await yt.videos.insert({
    part: ['snippet', 'status'],
    requestBody: {
      snippet: {
        title:       spec.title,
        description: spec.description || '',
        tags:        spec.tags || [],
        categoryId:  spec.category_id || '22',
      },
      status: {
        privacyStatus: spec.privacy || 'private',
      },
    },
    media: {
      body: fs.createReadStream(spec.file),
    },
  }, {
    onUploadProgress: (evt) => {
      const pct = Math.round((evt.bytesRead / fileSize) * 100);
      process.stdout.write(`\r  업로드 중... ${pct}% (${(evt.bytesRead / 1024 / 1024).toFixed(1)} MB)`);
    },
  });

  console.log('');
  const videoId = res.data.id;
  console.log(`  ✅ 업로드 완료: https://youtu.be/${videoId}`);

  // 썸네일 업로드 (있으면)
  if (spec.thumbnail && fs.existsSync(spec.thumbnail)) {
    try {
      await yt.thumbnails.set({
        videoId,
        media: { body: fs.createReadStream(spec.thumbnail) },
      });
      console.log(`  썸네일 업로드 완료`);
    } catch (e) {
      console.log(`  ⚠ 썸네일 실패: ${e.message}`);
    }
  }

  return videoId;
}

// ─── 메인 ──────────────────────────────────────────────────────
(async () => {
  console.log(`=== YouTube 업로드 v1.0 === [${account.email}]`);

  let successCount = 0;
  let failCount = 0;

  for (const filePath of uploadFiles) {
    const fileName = path.basename(filePath);
    console.log(`\n${'='.repeat(50)}\n스펙: ${fileName}`);

    let spec;
    try {
      spec = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    } catch (e) {
      console.log(`  JSON 파싱 실패: ${e.message}`);
      failCount++;
      continue;
    }

    // 계정 필터
    if (spec.account && spec.account !== accountId) {
      console.log(`  계정 불일치 (${spec.account} ≠ ${accountId}) — 스킵`);
      continue;
    }

    try {
      const videoId = await uploadVideo(spec);
      if (videoId) {
        successCount++;
        const doneDir = path.join(UPLOADS_DIR, 'done');
        fs.mkdirSync(doneDir, { recursive: true });
        const doneSpec = { ...spec, video_id: videoId, uploaded_at: new Date().toISOString() };
        fs.writeFileSync(path.join(doneDir, fileName), JSON.stringify(doneSpec, null, 2));
        fs.unlinkSync(filePath);
        console.log(`  파일 이동: uploads/done/${fileName}`);
      } else {
        failCount++;
      }
    } catch (e) {
      console.log(`  ❌ 업로드 실패: ${e.message}`);
      failCount++;
    }
    await sleep(2000);
  }

  console.log(`\n${'='.repeat(50)}`);
  console.log(`성공: ${successCount}  실패: ${failCount}`);
  console.log('완료');
})();
