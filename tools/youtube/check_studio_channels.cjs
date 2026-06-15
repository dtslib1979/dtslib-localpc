const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const profDir = path.join(require('os').homedir(), '.dtslib-youtube-profiles', 'account_a');
  const ctx = await chromium.launchPersistentContext(profDir, {
    channel: 'chrome', headless: false, viewport: { width: 1280, height: 900 },
  });
  const page = await ctx.newPage();
  
  await page.goto('https://studio.youtube.com', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await new Promise(r => setTimeout(r, 5000));
  
  // 좌측 사이드바 채널 아바타/아이콘 클릭
  const avatar = await page.$('ytcp-channel-watermark, img[src*="ggpht"], img[src*="photo"], #avatar').catch(() => null)
    || await page.locator('ytcp-navigation-drawer img').first().elementHandle().catch(() => null);
  if (avatar) {
    console.log('아바타 찾음 — 클릭');
    await avatar.click();
    await new Promise(r => setTimeout(r, 2000));
    await page.screenshot({ path: '/tmp/studio_switcher.png' });
    
    // 채널 목록 텍스트 수집
    const items = await page.evaluate(() => {
      const all = document.querySelectorAll('[role="menuitem"], [role="option"], ytcp-channel-select-item, ytcp-account-picker-list-item');
      return [...all].map(el => el.innerText?.trim().substring(0, 60)).filter(t => t);
    });
    console.log('채널 목록:', JSON.stringify(items));
  } else {
    console.log('아바타 못 찾음');
    // 모든 이미지 확인
    const imgs = await page.$$eval('img', els => els.map(e => ({src: e.src?.substring(0,60), alt: e.alt})));
    console.log('Images:', JSON.stringify(imgs.slice(0,10)));
  }
  
  await ctx.close();
})();
