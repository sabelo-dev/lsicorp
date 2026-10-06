// Checks wheel and touchpad scrolling in a real browser, by distance.
//
// A touchpad sends a stream of small movements, often fractions of a pixel; a
// mouse wheel sends a few large steps. Whatever the delivery, the page must
// move by the total distance reported. This drives headless Chrome over its
// debugging protocol and compares screenshots pixel by pixel.
//
//   npm run serve                      (in another terminal)
//   node scripts/wheel-check.mjs [url] [output directory]
import { spawn } from 'node:child_process';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// A page with no animation, so that position is the only thing that changes.
const url = process.argv[2] ?? 'http://localhost:8080/#/services';
const out = process.argv[3] ?? mkdtempSync(join(tmpdir(), 'wheel-check-'));
mkdirSync(out, { recursive: true });
const chromePath = process.env.CHROME ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const port = 9333;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const chrome = spawn(chromePath, [
  '--headless=new', '--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--no-first-run',
  `--user-data-dir=${mkdtempSync(join(tmpdir(), 'wheel-profile-'))}`, `--remote-debugging-port=${port}`,
  '--window-size=1100,800', 'about:blank',
], { stdio: 'ignore' });

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
  socket.onmessage = (event) => {
    const message = JSON.parse(event.data);
    pending.get(message.id)?.(message.result);
    pending.delete(message.id);
  };
  const send = (method, params = {}) =>
    new Promise((resolve) => {
      pending.set(++id, resolve);
      socket.send(JSON.stringify({ id, method, params }));
    });

  const at = { x: 550, y: 450 };
  const wheel = (deltaY) => send('Input.dispatchMouseEvent', { type: 'mouseWheel', ...at, deltaX: 0, deltaY });
  /** Sends `count` wheel events of `step` pixels each, then waits for the page to settle. */
  async function scroll(step, count, gap = 8) {
    for (let i = 0; i < count; i++) {
      await wheel(step);
      await sleep(gap);
    }
    await sleep(1600);
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

  await send('Page.navigate', { url });
  // The app is ready when the loading screen has been swapped for the canvas.
  for (let i = 0; i < 120; i++) {
    await sleep(500);
    const { result } = await send('Runtime.evaluate', { expression: "document.getElementById('loading').hidden" });
    if (result.value === true) break;
  }
  await sleep(1500);
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', ...at });
  await sleep(1600);

  const SAME = 0.004; // scrollbar position and anti-aliasing account for a fraction of a percent
  const MOVED = 0.02;

  const top = await shot('1-top');
  await scroll(4, 60); // 240 px as a touchpad sends it
  const afterSmall = await shot('2-after-60-steps-of-4px');
  await scroll(-240, 1); // back in one step
  const backInOne = await shot('3-back-in-one-step');
  await scroll(0.8, 300, 4); // 240 px in fractions of a pixel
  const afterFractions = await shot('4-after-300-steps-of-0.8px');
  await scroll(-0.5, 480, 4); // and back, again in fractions
  const backInFractions = await shot('5-back-in-fractions');
  await scroll(100, 3, 150); // three notches of a mouse wheel
  const afterNotches = await shot('6-after-3-wheel-notches');
  await scroll(-3, 100); // 300 px back as a touchpad sends it
  const backFromNotches = await shot('7-back-from-notches');

  const checks = [
    ['small touchpad steps move the page', await difference(top, afterSmall), (d) => d > MOVED],
    ['one large step returns exactly as far as 60 small steps went', await difference(top, backInOne), (d) => d < SAME],
    ['fractional steps cover the same distance as whole ones', await difference(afterSmall, afterFractions), (d) => d < SAME],
    ['fractional steps return to the top', await difference(top, backInFractions), (d) => d < SAME],
    ['a mouse wheel moves the page', await difference(top, afterNotches), (d) => d > MOVED],
    ['wheel notches and touchpad steps cover the same distance', await difference(top, backFromNotches), (d) => d < SAME],
  ];
  let failed = false;
  for (const [name, value, ok] of checks) {
    const pass = ok(value);
    failed ||= !pass;
    console.log(`${pass ? 'ok  ' : 'FAIL'} ${name} (${(value * 100).toFixed(2)}% of pixels differ)`);
  }
  console.log(`Screenshots in ${out}`);
  process.exitCode = failed ? 1 : 0;
  socket.close();
} finally {
  chrome.kill();
}
