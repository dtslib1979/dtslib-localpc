const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

const SECRET_PATH = path.join(__dirname, 'client_secret.json');
const CHANNELS_PATH = path.join(__dirname, 'accounts/channels.json');
const OUTPUT_PATH = path.join(__dirname, '../../hq/youtube-data.json');

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

async function getVideos(yt, channelId, maxResults = 50) {
  try {
    // 1. 업로드 재생목록 ID 조회
    const chRes = await yt.channels.list({
      part: ['contentDetails'],
      id: [channelId]
    });
    const uploadsId = chRes.data.items?.[0]?.contentDetails?.relatedPlaylists?.uploads;
    if (!uploadsId) return [];

    // 2. 재생목록 아이템 조회
    const plRes = await yt.playlistItems.list({
      part: ['snippet'],
      playlistId: uploadsId,
      maxResults
    });
    const items = plRes.data.items || [];
    if (!items.length) return [];

    const videoIds = items.map(i => i.snippet.resourceId.videoId).join(',');

    // 3. 영상 상세 조회 (statistics, contentDetails 포함)
    const vRes = await yt.videos.list({
      part: ['snippet', 'statistics', 'contentDetails'],
      id: [videoIds]
    });

    return (vRes.data.items || []).map(v => ({
      videoId: v.id,
      title: v.snippet.title,
      publishedAt: v.snippet.publishedAt,
      categoryId: v.snippet.categoryId,
      thumbnail: v.snippet.thumbnails?.medium?.url || v.snippet.thumbnails?.default?.url || null,
      viewCount: parseInt(v.statistics?.viewCount || 0),
      likeCount: parseInt(v.statistics?.likeCount || 0),
      commentCount: parseInt(v.statistics?.commentCount || 0),
      duration: v.contentDetails?.duration || null
    }));
  } catch (e) {
    return [];
  }
}

async function exportData() {
  console.log('YouTube 데이터 수집 시작...\n');

  const result = {
    updated: new Date().toISOString(),
    accounts: []
  };

  for (const account of accounts) {
    const tokenPath = path.join(__dirname, account.token_file);

    if (!fs.existsSync(tokenPath)) {
      console.log(`[${account.email}] ⚠ 토큰 없음`);
      result.accounts.push({ email: account.email, error: '토큰 없음', channels: [] });
      continue;
    }

    const tokens = JSON.parse(fs.readFileSync(tokenPath));
    const oauth2 = new google.auth.OAuth2(client_id, client_secret, 'http://localhost:3000/callback');
    oauth2.setCredentials(tokens);

    oauth2.on('tokens', (newTokens) => {
      const updated = { ...tokens, ...newTokens };
      fs.writeFileSync(tokenPath, JSON.stringify(updated, null, 2));
    });

    const yt = google.youtube({ version: 'v3', auth: oauth2 });
    const accountData = { email: account.email, channels: [] };

    for (const ch of account.channels) {
      process.stdout.write(`  ${ch.handle} ... `);
      try {
        const data = await getChannelByHandle(yt, ch.handle);
        if (!data) {
          console.log('채널 없음');
          continue;
        }

        const channelId = data.id;
        const s = data.statistics;

        process.stdout.write('영상 목록 조회 중... ');
        const videos = await getVideos(yt, channelId);
        console.log(`${videos.length}개`);

        accountData.channels.push({
          handle: ch.handle,
          repo: ch.repo,
          channelId,
          name: data.snippet.title,
          description: data.snippet.description?.slice(0, 200) || '',
          stats: {
            subscriberCount: parseInt(s.subscriberCount || 0),
            viewCount: parseInt(s.viewCount || 0),
            videoCount: parseInt(s.videoCount || 0)
          },
          videos
        });
      } catch (e) {
        console.log(`오류: ${e.message}`);
      }
    }

    result.accounts.push(accountData);
    console.log('');
  }

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(result, null, 2));
  console.log(`\n✅ 저장: ${OUTPUT_PATH}`);

  // 요약
  const totalChannels = result.accounts.reduce((n, a) => n + a.channels.length, 0);
  const totalVideos = result.accounts.reduce((n, a) =>
    n + a.channels.reduce((m, c) => m + c.videos.length, 0), 0);
  console.log(`   채널 ${totalChannels}개 | 영상 ${totalVideos}개`);
}

exportData().catch(console.error);
