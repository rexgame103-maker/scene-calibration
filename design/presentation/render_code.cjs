const {chromium} = require('C:/Users/REX/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const {pathToFileURL} = require('node:url');
const path = require('node:path');
const fs = require('node:fs');
const stem = '05-code-architecture';

(async () => {
  const browser = await chromium.launch({executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless:true});
  try {
    const page = await browser.newPage({viewport:{width:1920,height:1080},deviceScaleFactor:1});
    await page.goto(pathToFileURL(path.join(__dirname,`${stem}.svg`)).href);
    await page.evaluate(async () => {
      await document.fonts.ready;
      await Promise.all([...document.querySelectorAll('image')].map(el => new Promise((resolve,reject) => {
        const img=new Image(); img.onload=resolve; img.onerror=reject; img.src=el.getAttribute('href');
      })));
    });
    const audit = await page.evaluate(() => {
      const issues=[];
      const ctx=new OffscreenCanvas(1,1).getContext('2d');
      const texts=[...document.querySelectorAll('text')];
      const groups=texts.map(t=>{
        const style=getComputedStyle(t);
        ctx.font=`${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
        const lines=t.querySelectorAll('tspan').length ? [...t.querySelectorAll('tspan')] : [t];
        const polygons=lines.map(line=>{
          const box=line.getBBox(), m=ctx.measureText(line.textContent), y=Number(line.getAttribute('y'));
          const top=y-m.actualBoundingBoxAscent, bottom=y+m.actualBoundingBoxDescent;
          const matrix=line.getCTM();
          return [[box.x,top],[box.x+box.width,top],[box.x+box.width,bottom],[box.x,bottom]]
            .map(([x,y])=>new DOMPoint(x,y).matrixTransform(matrix)).map(p=>({x:p.x,y:p.y}));
        });
        return {t,polygons};
      });
      // Separating-axis test uses transformed glyph polygons, not local boxes.
      // Thus tilted photograph captions are checked in their final positions.
      const overlaps=(a,b)=>{
        for(const poly of [a,b]) for(let i=0;i<poly.length;i++){
          const p=poly[i],q=poly[(i+1)%poly.length];
          let nx=-(q.y-p.y),ny=q.x-p.x;
          const length=Math.hypot(nx,ny); if(length<.1) return false;
          nx/=length;ny/=length;
          const pa=a.map(v=>v.x*nx+v.y*ny),pb=b.map(v=>v.x*nx+v.y*ny);
          if(Math.min(Math.max(...pa),Math.max(...pb))-Math.max(Math.min(...pa),Math.min(...pb))<=1.2) return false;
        }
        return true;
      };
      for(const {t,polygons} of groups){
        for(const points of polygons) if(points.some(p=>p.x<30||p.x>1890||p.y<24||p.y>1061))
          issues.push({type:'page-bounds',text:t.textContent,points});
        if(t.hasAttribute('data-column-width')){
          const local=t.getBBox(),x=Number(t.getAttribute('data-column-x')),w=Number(t.getAttribute('data-column-width'));
          if(local.x<x-1||local.x+local.width>x+w+1)issues.push({type:'column-overflow',text:t.textContent,width:local.width,available:w});
        }
      }
      for(let i=0;i<groups.length;i++)for(let j=i+1;j<groups.length;j++){
        if(groups[i].polygons.some(a=>groups[j].polygons.some(b=>overlaps(a,b))))
          issues.push({type:'text-overlap',first:groups[i].t.textContent,second:groups[j].t.textContent});
      }
      const imageInfo=[...document.querySelectorAll('image')].map(el=>({embedded:el.getAttribute('href').startsWith('data:image/')}));
      return {pageSize:[1920,1080],textElements:texts.length,images:imageInfo.length,selfContained:imageInfo.every(i=>i.embedded),issues};
    });
    await page.screenshot({path:path.join(__dirname,`${stem}.png`)});
    fs.writeFileSync(path.join(__dirname,`${stem}-audit.json`),JSON.stringify(audit,null,2));
    const copy=await page.evaluate(()=>[...document.querySelectorAll('text')].map(t=>t.querySelectorAll('tspan').length?[...t.querySelectorAll('tspan')].map(s=>s.textContent).join(' '):t.textContent).join('\n'));
    fs.writeFileSync(path.join(__dirname,`${stem}-copy.txt`),copy);
    console.log(JSON.stringify(audit,null,2));
    if(audit.issues.length)process.exitCode=1;
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});

