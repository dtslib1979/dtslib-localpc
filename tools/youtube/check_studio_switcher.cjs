const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const profDir = path.join(require('os').homedir(), '.dtslib-youtube-profiles', 'account_a');
  const ctx = await chromium.launchPersistentContext(profDir, {
    channel: 'chrome', headless: false, viewport: { width: 1280, height: 900 },
  });
  const page = await ctx.newPage();
  
  // YouTube Studio 메인 (현재 채널 표시됨)
  await page.goto('https://studio.youtube.com', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await new Promise(r => setTimeout(r, 5000));
  await page.screenshot({ path: '/tmp/studio_main.png' });
  console.log('Studio URL:', page.url());
  console.log('Title:', await page.title());
  
  // 좌측 사이드바 채널 전환 버튼 찾기
  const allBtns = await page.$$eval('button, [role="button"]', els => 
    els.map(e => ({ text: e.innerText.trim(), cls: e.className })).filter(e => e.text)
  );
  console.log('All buttons:', JSON.stringify(allBtns.slice(0, 20)));
  
  // 채널 목록 얻기
  const channelItems = await page.evaluate(() => {
    const items = document.querySelectorAll('ytcp-channel-select-menu, ytcp-select, #channel-title, .channel-switcher');
    return [...items].map(el => ({ tag: el.tagName, text: el.innerText?.substring(0, 50) }));
  });
  console.log('Channel items:', JSON.stringify(channelItems));
  
  await ctx.close();
})();
