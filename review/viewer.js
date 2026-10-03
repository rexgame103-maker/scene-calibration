'use strict';
const review = JSON.parse(document.getElementById('review-data').textContent);
const files = new Map(review.files.map(file => [file.path, file]));
const workspace = document.getElementById('workspace');
const tree = document.getElementById('file-tree');
const searchDialog = document.getElementById('search-dialog');
const escapeHTML = value => String(value).replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const bytes = size => size >= 1048576 ? (size/1048576).toFixed(1)+' MB' : size >= 1024 ? (size/1024).toFixed(1)+' KB' : size+' B';
const fileHref = (path, line) => '#file='+encodeURIComponent(path)+(line ? '&line='+line : '');
const originalHref = path => '../'+path.split('/').map(encodeURIComponent).join('/');
const link = (path, label, line) => `<a href="${fileHref(path,line)}">${escapeHTML(label || path)}</a>`;
document.getElementById('snapshot').textContent = 'GODOT 4.7 / SNAPSHOT '+review.date;

function renderTree(query='') {
  tree.replaceChildren();
  const root = {children:new Map()};
  const selected = review.files.filter(file => file.path.toLowerCase().includes(query.toLowerCase()));
  document.getElementById('file-count').textContent = `${selected.length.toLocaleString()} 个文件 · ${review.files.filter(file=>'text' in file).length} 个文本文件`;
  for(const file of selected) {
    let parent=root;
    const parts=file.path.split('/');
    parts.forEach((name,index) => {
      if(!parent.children.has(name)) parent.children.set(name,{name,children:new Map()});
      parent=parent.children.get(name);
      if(index===parts.length-1) parent.file=file;
    });
  }
  function build(parent,target,depth) {
    const entries=[...parent.children.values()].sort((a,b)=>Number(Boolean(a.file))-Number(Boolean(b.file)) || a.name.localeCompare(b.name));
    for(const entry of entries) {
      if(entry.file) {
        const anchor=document.createElement('a');
        anchor.className='file-link';anchor.href=fileHref(entry.file.path);anchor.dataset.path=entry.file.path;anchor.title=entry.file.path;
        const badge=document.createElement('span');badge.className='file-ext';badge.textContent=entry.file.extension.replace('.','').slice(0,4)||'·';
        anchor.append(badge,document.createTextNode(entry.name));target.append(anchor);
      } else {
        const folder=document.createElement('details');
        folder.open=Boolean(query)||(depth===0&&['scripts','data','docs'].includes(entry.name));
        const summary=document.createElement('summary');summary.textContent=entry.name;
        const children=document.createElement('div');children.className='children';
        folder.append(summary,children);target.append(folder);build(entry,children,depth+1);
      }
    }
  }
  build(root,tree,0);highlightSelection();
}

function highlightSelection() {
  const selected=new URLSearchParams(location.hash.slice(1)).get('file');
  for(const anchor of tree.querySelectorAll('.file-link')) {
    const active=anchor.dataset.path===selected;anchor.classList.toggle('active',active);
    if(active) for(let parent=anchor.parentElement;parent&&parent!==tree;parent=parent.parentElement) if(parent.tagName==='DETAILS') parent.open=true;
  }
}

function overview() {
  const text=review.files.filter(file=>'text' in file);
  const code=text.filter(file=>['.gd','.py','.gdshader','.gdshaderinc','.js','.cjs','.mjs','.css'].includes(file.extension));
  const roots=[['scripts/','游戏逻辑与运行时界面'],['scenes/','Godot 场景与节点层级'],['data/','案件、线索与进程配置'],['assets/','模型、图集、照片与字体'],['materials/ · shaders/','材质与手绘画面效果'],['tests/ · tools/','功能验证与资源处理'],['docs/ · review/','审核导览与源码浏览页']];
  workspace.innerHTML=`<div class="eyebrow">Scene Calibration / Source Review</div><h1>从入口到每一行源码。</h1><p class="intro">错位现场是一款现场重构推理游戏。本页从当前工程直接生成，收录完整文件结构、文本源码与资源清单。先从模块导览开始，也可以通过左侧目录或全文检索定位代码。</p><div class="stats"><div class="stat"><strong>${review.files.length.toLocaleString()}</strong><small>工程文件</small></div><div class="stat"><strong>${text.length.toLocaleString()}</strong><small>可审阅文本文件</small></div><div class="stat"><strong>${code.reduce((total,file)=>total+file.lines,0).toLocaleString()}</strong><small>代码行（含工具与验证）</small></div><div class="stat"><strong>6</strong><small>全局管理器</small></div></div><h2>运行主线</h2><div class="flow">${link('project.godot','工程配置')}<span class="arrow">→</span>${link(review.entry,'开始菜单')}<span class="arrow">→</span>${link('scenes/studio/calibrator_studio.tscn','玩家工作室')}<span class="arrow">→</span>${link('scripts/game_flow.gd','接取案件')}<span class="arrow">→</span>${link('scenes/main.tscn','案件现场')}</div><p class="muted">在 Godot 4.7 中导入 project.godot，等待资源导入后按 F5。案件 JSON 由 CaseManager 加载；空间条件由 ReconstructionManager 组合判定。</p><h2>按功能阅读源码</h2><div class="modules">${review.modules.map(module=>`<section class="module"><h3>${escapeHTML(module.title)}</h3><p>${escapeHTML(module.description)}</p>${module.paths.map(path=>link(path)).join('')}</section>`).join('')}</div><h2>工程目录</h2><table class="directory-overview"><thead><tr><th>目录</th><th>职责</th></tr></thead><tbody>${roots.map(([path,description])=>`<tr><td><code>${escapeHTML(path)}</code></td><td>${escapeHTML(description)}</td></tr>`).join('')}</tbody></table><div class="notice">文本源码直接嵌入本页，双击打开即可使用，不需要启动服务器。二进制场景、模型和图片保留在原目录，可以下载原文件或在 Godot 中查看。未收录导入缓存、Git 内部目录、历史备份和交付 ZIP。</div><p class="muted">快照日期 ${review.date} · 文件清单包含 SHA-256 · 测试文件的收录不代表全部测试已通过</p>`;
}

function syntax(line,extension) {
  if(!['.gd','.py','.gdshader','.js','.cjs','.mjs','.css'].includes(extension)) return escapeHTML(line);
  // Match complete tokens before escaping; source is never inserted as HTML.
  const tokens=/("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|#.*$|\/\/.*$|\b(?:func|static|var|const|class_name|extends|signal|if|elif|else|for|while|return|await|true|false|null|and|or|not|in|match|break|continue|class|def|import|from|try|except|with|as|pass|void|shader_type|uniform|varying|render_mode|function|let|new)\b|\b\d+(?:\.\d+)?\b)/g;
  let result='',offset=0;
  for(const token of line.matchAll(tokens)) {
    result+=escapeHTML(line.slice(offset,token.index));
    const value=token[0];
    const kind=value.startsWith('#')||value.startsWith('//')?'comment':value.startsWith('"')||value.startsWith("'")?'string':/^\d/.test(value)?'number':'keyword';
    result+=`<span class="token-${kind}">${escapeHTML(value)}</span>`;offset=token.index+value.length;
  }
  return result+escapeHTML(line.slice(offset));
}

let currentPath='';
function showFile(path,line=0) {
  const file=files.get(path);
  if(!file){workspace.innerHTML='<div class="error">文件未在这份源码快照中收录。请通过左侧目录重新选择。</div>';return;}
  if(currentPath===path && document.getElementById('code-lines')){selectLine(line);return;}
  currentPath=path;
  workspace.innerHTML=`<header class="file-header"><div><div class="eyebrow">${'text' in file?'Source File':'Project Resource'}</div><h1>${escapeHTML(path)}</h1><div class="file-meta">${escapeHTML(file.extension||'配置文件')} · ${bytes(file.size)}${'text' in file?' · '+file.lines.toLocaleString()+' 行':''}</div></div><div class="file-actions">${'text' in file?'<button id="copy-source" type="button">复制源码</button>':''}<a href="${originalHref(path)}" download>原文件</a></div></header>`;
  if('text' in file) {
    const layout=document.createElement('div');layout.className='source-layout';
    const wrap=document.createElement('div');wrap.className='code-wrap';wrap.setAttribute('aria-label','带行号的源码');
    const code=document.createElement('div');code.id='code-lines';code.className='code-lines';
    const lines=file.text.split('\n');if(lines.at(-1)==='') lines.pop();
    code.innerHTML=lines.map((value,index)=>`<div class="code-row" id="line-${index+1}"><a class="line-number" href="${fileHref(path,index+1)}" aria-label="第 ${index+1} 行">${index+1}</a><span class="code-text">${syntax(value.replace(/\r$/,''),file.extension)}</span></div>`).join('');
    wrap.append(code);layout.append(wrap);
    const outline=document.createElement('aside');outline.className='outline';
    outline.innerHTML=`<strong>文件目录</strong>${file.symbols.length?file.symbols.map(symbol=>link(path,`L${symbol.line}  ${symbol.label}`,symbol.line)).join(''):'<p class="muted">此文件没有函数或节点索引。可用浏览器 Ctrl F 查找当前文件。</p>'}<p class="hash">SHA-256<br>${file.sha256}</p>`;
    layout.append(outline);workspace.append(layout);selectLine(line);
    document.getElementById('copy-source').addEventListener('click',async event=>{
      try{await navigator.clipboard.writeText(file.text);event.target.textContent='已复制';}
      catch {const field=document.createElement('textarea');field.value=file.text;document.body.append(field);field.select();const copied=document.execCommand('copy');field.remove();event.target.textContent=copied?'已复制':'请使用原文件';}
    });
  } else {
    const panel=document.createElement('section');panel.className='binary';
    panel.innerHTML=`<h2>资源文件</h2><p>原始资源已保留在完整工程中。Godot 二进制场景和模型请使用编辑器查看；目录树和文件清单记录原路径与大小。</p><p class="hash">SHA-256 · ${file.sha256}</p>`;
    if(['.png','.jpg','.jpeg','.webp','.svg'].includes(file.extension)) {const image=document.createElement('img');image.src=originalHref(path);image.alt=path;panel.append(image);}
    workspace.append(panel);
  }
}

function selectLine(number) {
  document.querySelectorAll('.code-row.selected').forEach(row=>row.classList.remove('selected'));
  const row=number>0?document.getElementById('line-'+number):null;
  if(row){row.classList.add('selected');row.scrollIntoView({block:'center'});}
}

function route() {
  const params=new URLSearchParams(location.hash.slice(1));
  if(params.has('file')) showFile(params.get('file'),Math.max(0,Number(params.get('line'))||0));
  else {currentPath='';overview();}
  highlightSelection();
}

function openSearch(){searchDialog.showModal();document.getElementById('source-query').focus();}
function searchSource(query,caseSensitive) {
  const results=document.getElementById('search-results');results.replaceChildren();
  if(!query.trim()){document.getElementById('search-summary').textContent='输入搜索词后按 Enter。';return;}
  const needle=caseSensitive?query:query.toLowerCase();let count=0;let matches=0;
  for(const file of review.files) {
    if(!('text' in file)) continue;
    const lines=file.text.split('\n');
    for(let index=0;index<lines.length;index++) {
      const value=lines[index],position=(caseSensitive?value:value.toLowerCase()).indexOf(needle);
      if(position<0)continue;matches++;
      if(count>=300)continue;
      const item=document.createElement('a');item.className='search-result';item.href=fileHref(file.path,index+1);
      const start=Math.max(0,position-70),end=Math.min(value.length,position+query.length+140);
      item.innerHTML=`<strong>${escapeHTML(file.path)} : ${index+1}</strong><p>${start?'…':''}${escapeHTML(value.slice(start,position))}<mark>${escapeHTML(value.slice(position,position+query.length))}</mark>${escapeHTML(value.slice(position+query.length,end))}${end<value.length?'…':''}</p>`;
      item.addEventListener('click',()=>searchDialog.close());results.append(item);count++;
    }
  }
  document.getElementById('search-summary').textContent=matches?`共 ${matches.toLocaleString()} 处匹配${matches>300?'，显示前 300 处；可缩小搜索范围':''}`:'没有找到匹配的源码。';
}

document.getElementById('file-filter').addEventListener('input',event=>renderTree(event.target.value));
document.getElementById('search-all').addEventListener('click',openSearch);
document.getElementById('close-search').addEventListener('click',()=>searchDialog.close());
document.getElementById('search-form').addEventListener('submit',event=>{event.preventDefault();searchSource(document.getElementById('source-query').value,document.getElementById('case-sensitive').checked);});
document.addEventListener('keydown',event=>{if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='k'){event.preventDefault();if(!searchDialog.open)openSearch();}});
window.addEventListener('hashchange',route);
renderTree();route();
