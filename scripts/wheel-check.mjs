// Checks that the site scrolls in a real browser for both kinds of wheel input:
// a touchpad (a stream of small pixel deltas) and a mouse wheel (large steps).
// Drives headless Chrome over its debugging protocol and compares screenshots.
//
//   npm run serve                      (in another terminal)
//   node scripts/wheel-check.mjs [url] [output directory]
import { spawn } from 'node:child_process';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const url = process.argv[2] ?? 'http://localhost:8080/#/products/gold-digger';
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
  const shot = async (name) => {
    const { data } = await send('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(out, `${name}.png`), Buffer.from(data, 'base64'));
    return data;
  };
  const at = { x: Number(process.env.WHEEL_X ?? 550), y: Number(process.env.WHEEL_Y ?? 450) };
  const scale = Number(process.env.WHEEL_SCALE ?? 1);
  const wheel = (deltaY) => send('Input.dispatchMouseEvent', { type: 'mouseWheel', ...at, deltaX: 0, deltaY: deltaY * scale });

  await send('Page.navigate', { url });
  // The app is ready when the loading screen has been swapped for the canvas.
  for (let i = 0; i < 120; i++) {
    await sleep(500);
    const { result } = await send('Runtime.evaluate', { expression: "document.getElementById('loading').hidden" });
    if (result.value === true) break;
  }
  await sleep(1500);
  // A real pointer is somewhere on the page before it scrolls.
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', ...at });
  await sleep(300);

  const start = await shot('1-start');
  for (let i = 0; i < 60; i++) {
    await wheel(4);
    await sleep(16);
  }
  await sleep(600);
  const afterTouchpad = await shot('2-after-touchpad');
  for (let i = 0; i < 4; i++) {
    await wheel(100);
    await sleep(120);
  }
  await sleep(600);
  const afterWheel = await shot('3-after-mouse-wheel');
  for (let i = 0; i < 200; i++) {
    await wheel(-6);
    await sleep(8);
  }
  await sleep(600);
  const backUp = await shot('4-back-to-top');

  const results = {
    'touchpad scrolls down': afterTouchpad !== start,
    'mouse wheel scrolls further': afterWheel !== afterTouchpad,
    'touchpad scrolls back to the top': backUp === start,
  };
  for (const [name, ok] of Object.entries(results)) console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`);
  console.log(`Screenshots in ${out}`);
  process.exitCode = Object.values(results).every(Boolean) ? 0 : 1;
  socket.close();
} finally {
  chrome.kill();
}
