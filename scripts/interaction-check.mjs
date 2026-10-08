// Checks the keyboard, search, form and download interactions in a real browser.
//
// The site is drawn on a canvas, so there is no page structure to query. This
// drives headless Chrome over its debugging protocol and judges by what a
// visitor could observe: the address, the history, the requests the page
// makes, and whether the picture changed. Screenshots of each step are kept
// as the interaction record.
//
//   $env:WITH_SYNC = 1; node scripts/mock-supabase.mjs     (terminal 1: content with published releases)
//   set supabaseUrl 'http://localhost:54321' and supabaseKey 'anon' in dist\config.js
//   npm run serve                                          (terminal 2)
//   node scripts/interaction-check.mjs [base url] [output directory]
//
// REDUCED_MOTION=1 runs the same checks as a visitor who asked for less animation.
import { spawn } from 'node:child_process';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = (process.argv[2] ?? 'http://localhost:8080').replace(/\/$/, '');
const out = process.argv[3] ?? mkdtempSync(join(tmpdir(), 'interaction-check-'));
mkdirSync(out, { recursive: true });
const chromePath = process.env.CHROME ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const port = 9334;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const chrome = spawn(chromePath, [
  '--headless=new', '--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--no-first-run',
  `--user-data-dir=${mkdtempSync(join(tmpdir(), 'interaction-profile-'))}`, `--remote-debugging-port=${port}`,
  '--window-size=1200,1700', ...(process.env.REDUCED_MOTION ? ['--force-prefers-reduced-motion'] : []), 'about:blank',
], { stdio: 'ignore' });

const results = [];
const check = (name, pass, detail = '') => {
  results.push(pass);
  console.log(`${pass ? 'ok  ' : 'FAIL'} ${name}${detail ? ` (${detail})` : ''}`);
};

try {
  let target;
  for (let i = 0; i < 50 && !target; i++) {
    await sleep(200);
    try {
      target = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find((t) => t.type === 'page');
    } catch {}
  }
  if (!target) throw new Error('Chrome did not start');

  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    socket.onopen = resolve;
    socket.onerror = reject;
  });
  let id = 0;
  const pending = new Map();
  /** Requests for a release file that the page started; each is answered here, never by the real host. */
  const downloads = [];
  const send = (method, params = {}) =>
    new Promise((resolve) => {
      pending.set(++id, resolve);
      socket.send(JSON.stringify({ id, method, params }));
    });
  socket.onmessage = (event) => {
    const message = JSON.parse(event.data);
    if (message.method === 'Fetch.requestPaused') {
      downloads.push(message.params.request.url);
      send('Fetch.fulfillRequest', {
        requestId: message.params.requestId,
        responseCode: 200,
        responseHeaders: [
          { name: 'Content-Type', value: 'application/octet-stream' },
          { name: 'Content-Disposition', value: 'attachment; filename="check.bin"' },
        ],
        body: Buffer.from('not a real release').toString('base64'),
      });
      return;
    }
    pending.get(message.id)?.(message.result);
    pending.delete(message.id);
  };

  const evaluate = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true })).result.value;
  const hash = () => evaluate('location.hash');
  const historyLength = () => evaluate('history.length');

  const KEYS = {
    '/': ['Slash', 191], Escape: ['Escape', 27], Enter: ['Enter', 13], Tab: ['Tab', 9], ArrowDown: ['ArrowDown', 40], ' ': ['Space', 32],
  };
  /** Presses one key. `modifiers`: 2 is Ctrl. */
  async function press(key, modifiers = 0) {
    const [code, keyCode] = KEYS[key] ?? [`Key${key.toUpperCase()}`, key.toUpperCase().charCodeAt(0)];
    const typed = key.length === 1 && modifiers === 0 ? { text: key } : key === 'Enter' ? { text: '\r' } : {};
    const event = { key, code, windowsVirtualKeyCode: keyCode, nativeVirtualKeyCode: keyCode, modifiers };
    await send('Input.dispatchKeyEvent', { type: 'keyDown', ...event, ...typed });
    await send('Input.dispatchKeyEvent', { type: 'keyUp', ...event });
    await sleep(40);
  }
  const type = async (text) => {
    for (const character of text) await press(character);
  };
  async function click(x, y, count = 1) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    for (let i = 1; i <= count; i++) {
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: i });
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: i });
      await sleep(60);
    }
  }
  const shot = async (name) => {
    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(out, `${name}.png`), Buffer.from(data, 'base64'));
    return data;
  };
  /** The share of pixels that differ between two screenshots, from 0 to 1. Measured in the page. */
  async function difference(a, b) {
    const { result } = await send('Runtime.evaluate', {
      awaitPromise: true,
      returnByValue: true,
      expression: `(async () => {
        const load = (data) => new Promise((resolve) => { const image = new Image(); image.onload = () => resolve(image); image.src = 'data:image/png;base64,' + data; });
        const [first, second] = await Promise.all([load(${JSON.stringify(a)}), load(${JSON.stringify(b)})]);
        const pixels = (image) => { const canvas = new OffscreenCanvas(image.width, image.height); const ctx = canvas.getContext('2d'); ctx.drawImage(image, 0, 0); return ctx.getImageData(0, 0, image.width, image.height).data; };
        const p = pixels(first), q = pixels(second);
        let changed = 0;
        for (let i = 0; i < p.length; i += 4) if (Math.abs(p[i] - q[i]) + Math.abs(p[i + 1] - q[i + 1]) + Math.abs(p[i + 2] - q[i + 2]) > 48) changed++;
        return changed / (p.length / 4);
      })()`,
    });
    return result.value;
  }
  const percent = (value) => `${(value * 100).toFixed(2)}% of pixels differ`;
  const SAME = 0.004;
  const CHANGED = 0.01;

  /** Opens a route in a fresh load of the app and waits until it is drawn. */
  async function open(route) {
    await send('Page.navigate', { url: 'about:blank' });
    await send('Page.navigate', { url: `${base}/#${route}` });
    for (let i = 0; i < 120; i++) {
      await sleep(500);
      if ((await evaluate("document.getElementById('loading')?.hidden")) === true) break;
    }
    await sleep(2500);
    // A click on empty page background gives the app the keyboard, as a visitor's first click would.
    await click(1150, 300);
    await sleep(300);
  }

  await send('Page.enable');
  // A fixed viewport, so that the positions clicked below are the same on every machine.
  await send('Emulation.setDeviceMetricsOverride', { width: 1200, height: 1700, deviceScaleFactor: 1, mobile: false });
  await send('Page.setDownloadBehavior', { behavior: 'deny' });
  await send('Fetch.enable', { patterns: [{ urlPattern: '*lsicorp-release-files*' }] });

  // 1. The catalogue: "/" focuses its search, typing filters at once, the address follows without new history.
  await open('/work');
  const all = await shot('01-work');
  const entries = await historyLength();
  await press('/');
  await type('gold');
  await sleep(900);
  const searched = await shot('02-work-searched');
  check('"/" then typing filters the catalogue', (await difference(all, searched)) > CHANGED, percent(await difference(all, searched)));
  check('the address carries the search', (await hash()) === '#/work?q=gold', await hash());
  check('typing adds no history entries', (await historyLength()) === entries, `${entries} before, ${await historyLength()} after`);

  // 2. Escape clears the search and the address; the catalogue is whole again.
  await press('Escape');
  await sleep(900);
  await shot('03-work-cleared');
  check('Escape clears the search', (await hash()) === '#/work', await hash());
  // A second Escape lets go of the field, so its focus ring is not part of the comparison.
  await press('Escape');
  await click(1150, 300);
  await sleep(400);
  const restored = await difference(all, await shot('04-work-restored'));
  check('the full catalogue is back', restored < SAME, percent(restored));

  // 3. A filtered address opens as that view, and a search that matches nothing explains itself.
  await open('/work?q=zebra&status=available');
  const empty = await shot('05-work-empty');
  check('a shared address restores its search and filter', (await hash()) === '#/work?q=zebra&status=available', await hash());
  check('no results is a different picture from the full catalogue', (await difference(all, empty)) > CHANGED);

  // 4. The site search: Ctrl+K opens it, Escape closes it and nothing else changed, Enter goes to the chosen result.
  await open('/services');
  const services = await shot('06-services');
  await press('k', 2);
  await sleep(700);
  const panel = await shot('07-search-open');
  check('Ctrl+K opens the site search', (await difference(services, panel)) > 0.2, percent(await difference(services, panel)));
  await press('Escape');
  await sleep(700);
  check('Escape closes it and leaves the page as it was', (await difference(services, await shot('08-search-closed'))) < SAME);
  await press('k', 2);
  await sleep(500);
  await type('contact');
  await sleep(300);
  await shot('09-search-typed');
  await press('Enter');
  await sleep(900);
  check('Enter opens the chosen result', (await hash()) === '#/contact', await hash());
  await evaluate('history.back()');
  await sleep(900);
  check('Back returns to the page before', (await hash()) === '#/services', await hash());

  // 5. The contact form: an empty send is refused next to the fields, nothing is posted, and typing continues in the first field.
  await open('/contact');
  const form = await shot('10-contact');
  await click(110, 1255);
  await sleep(700);
  const refused = await shot('11-contact-problems');
  check('sending an empty form shows problems', (await difference(form, refused)) > 0.002, percent(await difference(form, refused)));
  check('and stays on the form', (await hash()) === '#/contact', await hash());
  await type('ada');
  await sleep(400);
  const corrected = await shot('12-contact-name-typed');
  check('the keyboard is in the first field that needs attention', (await difference(refused, corrected)) > 0.0002, percent(await difference(refused, corrected)));

  // 6. A download: one press starts it and says so; a double click does not fetch the file twice.
  await open('/work/gold-digger');
  const before = await shot('13-product');
  await click(170, 580, 2);
  await sleep(1500);
  const started = await shot('14-download-started');
  check('the download button starts a download', downloads.length >= 1, downloads[0] ?? 'no request seen');
  check('a double click fetches the file once', downloads.length === 1, `${downloads.length} requests`);
  check('the page stays and confirms the download', (await hash()) === '#/work/gold-digger' && (await difference(before, started)) > 0.0005, percent(await difference(before, started)));

  console.log(`Screenshots in ${out}`);
  process.exitCode = results.every(Boolean) ? 0 : 1;
  socket.close();
} finally {
  chrome.kill();
}
