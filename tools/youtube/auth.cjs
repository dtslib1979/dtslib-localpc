const { google } = require('googleapis');
const fs = require('fs');
const http = require('http');
const url = require('url');
const path = require('path');

const SECRET_PATH = path.join(__dirname, 'client_secret.json');

const SCOPES = [
  'https://www.googleapis.com/auth/youtube',
  'https://www.googleapis.com/auth/yt-analytics.readonly',
  'https://www.googleapis.com/auth/spreadsheets',
  'https://www.googleapis.com/auth/drive.file'
];

async function getToken(accountId) {
  const accounts = {
    a: { email: 'dimas.thomas.sancho@gmail.com', token: 'accounts/token_a.json' },
    b: { email: 'dtslib1979@gmail.com',          token: 'accounts/token_b.json' },
    c: { email: 'Thomas.tj.Park@gmail.com',      token: 'accounts/token_c.json' },
    d: { email: 'dimas@dtslib.com',              token: 'accounts/token_d.json' }
  };

  const account = accounts[accountId];
  if (!account) {
    console.log('사용법: node auth.js [a|b|c|d]');
    console.log('  a = dimas.thomas.sancho@ (parksy 5채널)');
    console.log('  b = dtslib1979@ (6채널)');
    console.log('  c = Thomas.tj.Park@ (EAE 2채널)');
    console.log('  d = dimas@dtslib.com (dtslib 2채널)');
    process.exit(1);
  }

  const TOKEN_PATH = path.join(__dirname, account.token);
  const secret = JSON.parse(fs.readFileSync(SECRET_PATH));
  const { client_id, client_secret } = secret.installed;

  const oauth2 = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3000/callback');
  const authUrl = oauth2.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
    login_hint: account.email
  });

  console.log(`\n[계정 ${accountId.toUpperCase()}] ${account.email}`);
  console.log('\n브라우저에서 아래 URL 열어:\n');
  console.log(authUrl);
  console.log('\nlocalhost:3000 대기 중...\n');

  const code = await new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const qs = url.parse(req.url, true).query;
      if (qs.code) {
        res.end('<h1>완료. 터미널로 돌아가.</h1>');
        server.close();
        resolve(qs.code);
      }
    }).listen(3000);
  });

  const { tokens } = await oauth2.getToken(code);
  fs.mkdirSync(path.join(__dirname, 'accounts'), { recursive: true });
  fs.writeFileSync(TOKEN_PATH, JSON.stringify(tokens, null, 2));
  console.log(`\ntoken 저장: ${TOKEN_PATH}`);
}

const accountId = process.argv[2];
getToken(accountId).catch(console.error);
