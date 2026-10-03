// DOM behavior checks; no browser, network, resource loading or player saves.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM, VirtualConsole } = require(process.env.JSDOM_MODULE || 'jsdom');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'review/index.html'), 'utf8');
const errors = [];
const consoleBridge = new VirtualConsole();
consoleBridge.on('jsdomError', error => errors.push(error.message));
let copied = '';
const dom = new JSDOM(html, {
  runScripts: 'dangerously', url: 'https://source-review.invalid/review/index.html',
  virtualConsole: consoleBridge,
  beforeParse(window) {
    window.HTMLElement.prototype.scrollIntoView = function () {};
    window.HTMLDialogElement.prototype.showModal = function () { this.open = true; };
    window.HTMLDialogElement.prototype.close = function () { this.open = false; };
    Object.defineProperty(window.navigator, 'clipboard', { value: { writeText: async text => { copied = text; } } });
  },
});
const { window } = dom;
const document = window.document;
const data = JSON.parse(document.getElementById('review-data').textContent);
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
const getFile = filePath => data.files.find(file => file.path === filePath);
async function navigate(filePath, line = 0) {
  window.location.hash = '#file=' + encodeURIComponent(filePath) + (line ? '&line=' + line : '');
  await tick();
}

(async () => {
  assert.equal(document.querySelectorAll('.module').length, 6, 'All module guides render');
  assert.equal(document.querySelectorAll('.file-link').length, data.files.length, 'Directory includes every delivered file');
  assert.equal(data.files.some(file => /^(.git|.godot|Backups|deliveries)\//.test(file.path)), false, 'Local caches and packages are excluded');
  for (const module of data.modules) for (const filePath of module.paths) assert.ok(getFile(filePath), 'Module target exists: ' + filePath);
  await navigate('scripts/main.gd');
  assert.equal(document.querySelector('.file-header h1').textContent, 'scripts/main.gd');
  assert.equal(document.querySelectorAll('.code-row').length, getFile('scripts/main.gd').lines);
  const symbol = getFile('scripts/main.gd').symbols.find(item => item.label === 'func _refresh_inventory_ui');
  assert.ok(symbol);
  await navigate('scripts/main.gd', symbol.line);
  assert.equal(document.querySelector('.code-row.selected').id, 'line-' + symbol.line, 'Line link selects the requested source line');
  document.getElementById('copy-source').click(); await tick();
  assert.equal(copied, getFile('scripts/main.gd').text, 'Copy returns unchanged complete source');
  const filter = document.getElementById('file-filter');
  filter.value = 'reconstruction'; filter.dispatchEvent(new window.Event('input'));
  assert.ok(document.querySelectorAll('.file-link').length > 0);
  for (const item of document.querySelectorAll('.file-link')) assert.ok(item.dataset.path.includes('reconstruction'));
  document.getElementById('search-all').click();
  assert.equal(document.getElementById('search-dialog').open, true);
  document.getElementById('source-query').value = 'func _draw_icon';
  document.getElementById('search-form').dispatchEvent(new window.Event('submit', { cancelable: true }));
  const result = [...document.querySelectorAll('.search-result')].find(item => item.textContent.includes('scripts/catalog_item.gd'));
  assert.ok(result, 'Cross-file search finds real source');
  const selectedResult = new Promise(resolve => window.addEventListener('hashchange', resolve, { once: true }));
  result.click(); await selectedResult;
  assert.equal(document.getElementById('search-dialog').open, false);
  assert.equal(document.querySelector('.file-header h1').textContent, 'scripts/catalog_item.gd');
  assert.ok(document.querySelector('.code-row.selected .code-text').textContent.includes('func _draw_icon'));
  await navigate('scenes/main.tscn');
  assert.ok(document.querySelector('.outline').textContent.includes('PrimitiveRoom'), 'Scene node index renders');
  await navigate('assets/ui/furniture_handdrawn/office.png');
  assert.ok(document.querySelector('.binary img').getAttribute('src').endsWith('/office.png'));
  assert.ok(document.querySelector('.hash').textContent.includes(getFile('assets/ui/furniture_handdrawn/office.png').sha256));
  await navigate('does-not-exist.gd');
  assert.ok(document.querySelector('.error'), 'Invalid file link fails clearly');
  await navigate('project.godot');
  const original = fs.readFileSync(path.join(root, 'project.godot'), 'utf8').split(/\r?\n/);
  const rendered = [...document.querySelectorAll('.code-text')].map(item => item.textContent);
  if (original.at(-1) === '') original.pop();
  assert.deepEqual(rendered, original, 'Source display preserves text and line order');
  assert.deepEqual(errors, [], 'Embedded page scripts run without errors');
  console.log(`SOURCE_REVIEW_DOM_OK files=${data.files.length} modules=6 navigation=ok search=ok copy=ok scene_nodes=ok`);
  window.close();
})().catch(error => { console.error(error); window.close(); process.exitCode = 1; });
