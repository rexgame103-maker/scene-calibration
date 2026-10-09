const {chromium} = require('C:/Users/REX/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const {pathToFileURL} = require('node:url');
const path = require('node:path');
const fs = require('node:fs');

(async () => {
  const browser = await chromium.launch({executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', headless: true});
  try {
    const page = await browser.newPage({viewport: {width: 1920, height: 1080}, deviceScaleFactor: 1});
    const reports = [];
    for (const stem of ['01-cover', '02-inspiration-references']) {
      await page.goto(pathToFileURL(path.join(__dirname, `${stem}.svg`)).href);
      await page.evaluate(async () => {
        await document.fonts.ready;
        await Promise.all([...document.querySelectorAll('image')].map(el => new Promise((resolve,reject) => {
          const probe = new Image();
          probe.onload = resolve;
          probe.onerror = reject;
          probe.src = el.getAttribute('href');
        })));
      });
      const audit = await page.evaluate(() => {
        const issues = [];
        const texts = [...document.querySelectorAll('text')];
        // SVG getBBox includes unused font ascent/descent. Use painted glyph
        // metrics for vertical intersections, so uppercase display type is
        // checked against actual visible letters rather than its full em box.
        const context = new OffscreenCanvas(1,1).getContext('2d');
        function glyphBox(text) {
          const b=text.getBBox();
          const style=getComputedStyle(text);
          context.font=`${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
          const lines=text.querySelectorAll('tspan').length ? [...text.querySelectorAll('tspan')] : [text];
          let top=Infinity, bottom=-Infinity;
          for(const line of lines) {
            const m=context.measureText(line.textContent);
            const y=Number(line.getAttribute('y'));
            top=Math.min(top,y-m.actualBoundingBoxAscent);
            bottom=Math.max(bottom,y+m.actualBoundingBoxDescent);
          }
          return {x:b.x, y:top, width:b.width, height:bottom-top};
        }
        for (const text of texts) {
          const b = glyphBox(text);
          if (b.x < 30 || b.y < 24 || b.x + b.width > 1890 || b.y + b.height > 1061)
            issues.push({type: 'page-bounds', text: text.textContent, box: {x:b.x,y:b.y,width:b.width,height:b.height}});
          if (text.hasAttribute('data-column-width')) {
            const x = Number(text.getAttribute('data-column-x'));
            const w = Number(text.getAttribute('data-column-width'));
            if (b.x < x-1 || b.x+b.width > x+w+1)
              issues.push({type: 'column-overflow', text: text.textContent, box: {x:b.x,y:b.y,width:b.width,height:b.height}});
          }
        }
        for (let i=0; i<texts.length; i++) {
          for(let j=i+1;j<texts.length;j++) {
            const a=glyphBox(texts[i]), b=glyphBox(texts[j]);
            const overlapX=Math.min(a.x+a.width,b.x+b.width)-Math.max(a.x,b.x);
            const overlapY=Math.min(a.y+a.height,b.y+b.height)-Math.max(a.y,b.y);
            if(overlapX>2 && overlapY>2)
              issues.push({type:'text-overlap', first:texts[i].textContent, second:texts[j].textContent});
          }
        }
        return {textElements:texts.length, images:document.querySelectorAll('image').length, issues};
      });
      await page.screenshot({path: path.join(__dirname, `${stem}.png`)});
      reports.push({page:stem,...audit});
    }
    fs.writeFileSync(path.join(__dirname,'layout-audit.json'),JSON.stringify(reports,null,2));
    console.log(JSON.stringify(reports,null,2));
    if(reports.some(r=>r.issues.length)) process.exitCode=1;
  } finally {
    await browser.close();
  }
})().catch(e=>{console.error(e);process.exitCode=1;});
