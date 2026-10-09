// Check the generated offline review in a real browser without a server.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'C:/Users/REX/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root = path.resolve(__dirname,'..');

(async()=>{
  const browser=await chromium.launch({executablePath:process.env.EDGE_PATH || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
  try {
    const page=await browser.newPage();
    const errors=[];
    page.on('pageerror',error=>errors.push(error.message));
    await page.addInitScript(()=>{
      window.reviewClipboard='';
      Object.defineProperty(navigator,'clipboard',{value:{writeText:async text=>{window.reviewClipboard=text;}}});
    });
    const url=pathToFileURL(path.join(root,'review/index.html')).href;
    await page.goto(url);
    const overview=await page.evaluate(()=>{
      const payload=JSON.parse(document.getElementById('review-data').textContent);
      return {files:payload.files.length,tree:document.querySelectorAll('.file-link').length,
              modules:document.querySelectorAll('.module').length,autoloadCount:document.querySelector('.stats .stat:last-child strong').textContent,
              excluded:payload.files.some(f=>f.path.split('/').some(p=>['.git','.godot','.tooling','__pycache__'].includes(p)))};
    });
    assert.equal(overview.tree,overview.files);
    assert.equal(overview.modules,6);
    assert.equal(overview.autoloadCount,'8');
    assert.equal(overview.excluded,false);
    await page.evaluate(()=>{location.hash='#file=scripts%2Fterminal_app_window.gd&line=72';});
    await page.waitForSelector('#line-72.selected');
    assert.equal(await page.locator('.file-header h1').textContent(),'scripts/terminal_app_window.gd');
    await page.locator('#copy-source').click();
    assert.equal(await page.evaluate(()=>window.reviewClipboard),fs.readFileSync(path.join(root,'scripts/terminal_app_window.gd'),'utf8'));
    await page.locator('#file-filter').fill('scene_clue');
    assert.ok((await page.locator('.file-link').count())>0);
    assert.ok((await page.locator('.file-link').evaluateAll(links=>links.map(a=>a.dataset.path))).every(p=>p.includes('scene_clue')));
    await page.locator('#search-all').click();
    await page.locator('#source-query').fill('func toggle_maximized');
    await page.locator('#search-form').evaluate(form=>form.dispatchEvent(new Event('submit',{cancelable:true})));
    await page.locator('.search-result').filter({hasText:'scripts/terminal_app_window.gd'}).first().click();
    await page.waitForSelector('#line-72.selected');
    assert.equal(await page.locator('#search-dialog').evaluate(dialog=>dialog.open),false);
    await page.evaluate(()=>{location.hash='#file=scenes%2Fmain.tscn';});
    await page.waitForFunction(()=>document.querySelector('.file-header h1')?.textContent==='scenes/main.tscn');
    assert.ok((await page.locator('.outline').textContent()).includes('PrimitiveRoom'));
    await page.evaluate(()=>{location.hash='#file=does-not-exist.gd';});
    await page.waitForSelector('.error');
    assert.deepEqual(errors,[]);
    console.log('SOURCE_REVIEW_BROWSER_OK: '+JSON.stringify(overview)+' navigation, copy, search, line links, scene index and invalid-file feedback');
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
