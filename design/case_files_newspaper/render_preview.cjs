const { chromium } = require('C:/Users/REX/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const { pathToFileURL } = require('node:url');
const path = require('node:path');
(async () => {
  const browser = await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', headless:true});
  const page = await browser.newPage({viewport:{width:1600,height:900},deviceScaleFactor:1});
  for (const kind of ['photo','text']) {
    await page.goto(pathToFileURL(path.join(__dirname,`case_files_${kind}.svg`)).href);
    await page.evaluate(() => document.fonts.ready);
    await page.screenshot({path:path.join(__dirname,`case_files_${kind}.png`)});
  }
  await browser.close();
})();
