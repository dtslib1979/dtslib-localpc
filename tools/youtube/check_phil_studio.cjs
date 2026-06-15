const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const profDir = path.join(require('os').homedir(), '.dtslib-youtube-profiles', 'account_a');
  const ctx = await chromium.launchPersistentContext(profDir, {
    channel: 'chrome', headless: false, viewport: { width: 1280, height: 900 },
  });
  const page = await ctx.newPage();
  
  await page.goto('https://studio.youtube.com/channel/UCJaGuXjxoNjFMqfYUSFjZVg', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await new Promise(r => setTimeout(r, 3000));
  await page.screenshot({ path: '/tmp/studio_phil_01.png' });
  console.log('URL1:', page.url());
  
  // 계정 전환 버튼 찾기
  const btns = await page.$$eval('button, a', els => els.map(e => e.innerText.trim()).filter(t => t));
  console.log('Buttons:', JSON.stringify(btns.slice(0, 15)));
  
  const switchBtn = await page.$eval('button, a', el => {
    const all = document.querySelectorAll('button, a');
    for (const e of all) {
      if (e.innerText && e.innerText.includes('계정 전환')) return true;
    }
    return false;
  }).catch(() => false);
  
  if (switchBtn) {
    const el = await page.evaluate(() => {
      const all = document.querySelectorAll('button, a');
      for (const e of all) {
        if (e.innerText && e.innerText.includes('계정 전환')) { e.click(); return e.innerText; }
      }
    });
    console.log('Clicked:', el);
    await new Promise(r => setTimeout(r, 3000));
    await page.screenshot({ path: '/tmp/studio_phil_02.png' });
    console.log('URL2:', page.url());
    const txt = await page.evaluate(() => document.body.innerText.substring(0, 800)).catch(() => '');
    console.log('Text:', txt);
  }
  
  await ctx.close();
})();
