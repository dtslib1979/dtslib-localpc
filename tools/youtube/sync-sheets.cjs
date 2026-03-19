/**
 * sync-sheets.cjs — YouTube 통계 → Google Sheets 동기화 v1.0
 *
 * - hq/youtube-data.json (export.cjs 출력) 읽기
 * - Google Sheets API로 채널별 통계 기록
 * - 스프레드시트 ID는 환경변수 SHEET_ID 또는 accounts/sheets.json에서 로드
 *
 * 사전 준비:
 *   1. auth.cjs로 OAuth 토큰 발급 (scope에 spreadsheets 필요)
 *   2. Google Sheets에 스프레드시트 생성 후 ID 기록
 *   3. accounts/sheets.json 생성:
 *      { "spreadsheet_id": "1abc...", "account": "d" }
 *
 * 사용법:
 *   node sync-sheets.cjs
 */

'use strict';

const { google } = require('googleapis');
const fs   = require('fs');
const path = require('path');

const __dir         = __dirname;
const SECRET_PATH   = path.join(__dir, 'client_secret.json');
const SHEETS_CONFIG = path.join(__dir, 'accounts', 'sheets.json');
const DATA_PATH     = path.join(__dir, '../../hq/youtube-data.json');

if (!fs.existsSync(SHEETS_CONFIG)) {
  console.log('accounts/sheets.json 없음. 생성 방법:');
  console.log('{ "spreadsheet_id": "<ID>", "account": "d" }');
  process.exit(1);
}

const sheetsCfg = JSON.parse(fs.readFileSync(SHEETS_CONFIG));
const ACCOUNT_MAP = {
  a: 'accounts/token_a.json',
  b: 'accounts/token_b.json',
  c: 'accounts/token_c.json',
  d: 'accounts/token_d.json',
};

const accountId  = sheetsCfg.account || 'd';
const TOKEN_PATH = path.join(__dir, ACCOUNT_MAP[accountId]);
const SHEET_ID   = sheetsCfg.spreadsheet_id;

if (!fs.existsSync(TOKEN_PATH)) {
  console.log(`토큰 없음: ${TOKEN_PATH}`);
  console.log(`node auth.cjs ${accountId} 실행 필요`);
  process.exit(1);
}

if (!fs.existsSync(DATA_PATH)) {
  console.log(`YouTube 데이터 없음: ${DATA_PATH}`);
  console.log('node export.cjs 먼저 실행하세요.');
  process.exit(1);
}

// ─── OAuth2 ──────────────────────────────────────────────────
const secret = JSON.parse(fs.readFileSync(SECRET_PATH));
const { client_id, client_secret } = secret.installed;
const oauth2 = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3000/callback');
const tokens = JSON.parse(fs.readFileSync(TOKEN_PATH));
oauth2.setCredentials(tokens);
oauth2.on('tokens', (t) => {
  fs.writeFileSync(TOKEN_PATH, JSON.stringify({ ...tokens, ...t }, null, 2));
});

// ─── Sheets 동기화 ────────────────────────────────────────────
async function syncToSheets() {
  const data = JSON.parse(fs.readFileSync(DATA_PATH));
  const sheets = google.sheets({ version: 'v4', auth: oauth2 });

  const today = new Date().toISOString().slice(0, 10);
  const rows  = [['날짜', '계정', '채널', '핸들', '구독자', '조회수', '영상수']];

  for (const account of data.accounts) {
    for (const ch of account.channels || []) {
      rows.push([
        today,
        account.email,
        ch.name || '',
        ch.handle || '',
        ch.stats?.subscriberCount || 0,
        ch.stats?.viewCount || 0,
        ch.stats?.videoCount || 0,
      ]);
    }
  }

  // 탭 이름: STATS
  const sheetName = 'STATS';
  await sheets.spreadsheets.values.append({
    spreadsheetId: SHEET_ID,
    range:         `${sheetName}!A1`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });

  console.log(`✅ ${rows.length - 1}개 채널 통계 → Sheets 동기화 완료`);
  console.log(`   스프레드시트: https://docs.google.com/spreadsheets/d/${SHEET_ID}`);
}

syncToSheets().catch(console.error);
