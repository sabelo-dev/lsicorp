// Serves dist/ locally with the same response headers as production (read
// from customHttp.yml), so problems such as a Content-Security-Policy
// violation show up before deployment.
//
//   node scripts/serve.mjs [directory] [port]     default: dist 8080
import { createReadStream, existsSync, readFileSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = join(dirname(fileURLToPath(import.meta.url)), '..');
const root = resolve(process.argv[2] ?? join(repo, 'dist'));
const port = Number(process.argv[3] ?? 8080);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.gz': 'application/gzip',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.json': 'application/json',
  '.webmanifest': 'application/manifest+json',
  '.txt': 'text/plain; charset=utf-8',
};

/** The rules in customHttp.yml as [{ pattern, headers }]. Reads only the simple shape that file uses. */
function readRules() {
  const file = join(repo, 'customHttp.yml');
  if (!existsSync(file)) return [];
  const rules = [];
  let key = null;
  for (const line of readFileSync(file, 'utf8').split(/\r?\n/)) {
    const pattern = line.match(/^\s*- pattern:\s*'(.+)'\s*$/);
    const name = line.match(/^\s*- key:\s*(.+?)\s*$/);
    const value = line.match(/^\s*value:\s*(.+?)\s*$/);
    if (pattern) rules.push({ pattern: pattern[1], headers: {} });
    else if (name) key = name[1];
    else if (value && key && rules.length) rules.at(-1).headers[key] = value[1].replace(/^"(.*)"$/, '$1');
  }
  return rules;
}

const matches = (pattern, path) =>
  new RegExp(`^${pattern.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*\*/g, '.*').replace(/\*/g, '[^/]*')}$`).test(path);

function headersFor(path) {
  const headers = {};
  for (const rule of readRules()) if (matches(rule.pattern, path)) Object.assign(headers, rule.headers);
  // A local mock backend is not on *.supabase.co; allow it for local testing only.
  if (headers['Content-Security-Policy']) {
    headers['Content-Security-Policy'] = headers['Content-Security-Policy'].replace('connect-src', 'connect-src http://localhost:54321');
  }
  delete headers['Strict-Transport-Security'];
  return headers;
}

createServer((request, response) => {
  let path = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  if (path.endsWith('/')) path += 'index.html';
  const file = normalize(join(root, path));
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) {
    response.writeHead(404, { 'Content-Type': 'text/plain' }).end('Not found');
    return;
  }
  response.writeHead(200, {
    'Content-Type': TYPES[extname(file)] ?? 'application/octet-stream',
    'Content-Length': statSync(file).size,
    ...headersFor(path),
  });
  createReadStream(file).pipe(response);
}).listen(port, () => console.log(`Serving ${root} at http://localhost:${port}`));
