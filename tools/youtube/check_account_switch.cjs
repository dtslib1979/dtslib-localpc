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
  
  // 오른쪽 상단 계정 아이콘 (상단 바)
  const topAvatar = await page.$('#avatar-btn, ytcp-account-picker-button, button img[src*="ggpht"]').catch(() => null);
  if (topAvatar) {
    console.log('상단 계정 아이콘 클릭...');
    await topAvatar.click();
  } else {
    // 좌측 사이드바 아바타
    const sideAvatar = await page.locator('ytcp-navigation-drawer img').first().elementHandle().catch(() => null);
    if (sideAvatar) {
      console.log('사이드바 아바타 클릭...');
      await sideAvatar.click();
    }
  }
  await new Promise(r => setTimeout(r, 1500));
  
  // "계정 전환" 클릭 (서브메뉴 열기)
  const switched = await page.evaluate(() => {
    const all = document.querySelectorAll('a, button, [role="menuitem"], [role="option"], tp-yt-paper-item, ytcp-compact-link');
    for (const el of all) {
      const t = (el.innerText || el.textContent || '').trim();
      if (t === '계정 전환' || t.startsWith('계정 전환')) {
        el.click();
        return t;
      }
    }
    return null;
  });
  console.log('계정 전환 클릭:', switched);
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({ path: '/tmp/studio_acct_switch.png' });
  
  // 서브메뉴 채널 목록 수집
  const channels = await page.evaluate(() => {
    const all = document.querySelectorAll('[role="menuitem"], [role="option"], ytcp-account-picker-list-item, tp-yt-paper-item, a, li');
    const results = [];
    for (const el of all) {
      const t = (el.innerText || '').trim();
      if (t && t.length < 50 && t.length > 2 && !t.includes('\n\n')) results.push(t);
    }
    return [...new Set(results)];
  });
  console.log('서브메뉴 항목:', JSON.stringify(channels.slice(0, 30)));
  
  await ctx.close();
})();
