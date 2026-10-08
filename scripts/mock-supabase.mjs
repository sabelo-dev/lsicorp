// Local stand-in for a Supabase project, for development and testing only.
// It runs the real migrations and seed in an in-process Postgres and answers
// the subset of the REST and auth endpoints that the app uses, applying
// row-level security exactly as the migrations define it.
//
//   node scripts/mock-supabase.mjs            (http://localhost:54321)
//
// Then point the app at it: supabaseUrl "http://localhost:54321", any key.
// Sign in as editor@lsi.test, ann@lsi.test, ben@lsi.test (release managers)
// or admin@lsi.test, all with the password "password".
// Data lives in memory and is reset on every start.
import { readFileSync, readdirSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sql = (path) => readFileSync(join(root, path), 'utf8');
const port = Number(process.env.PORT ?? 54321);

const USERS = [
  ['00000000-0000-0000-0000-00000000000e', 'editor@lsi.test', 'Edith Editor', 'editor'],
  ['00000000-0000-0000-0000-00000000000a', 'ann@lsi.test', 'Ann Manager', 'release_manager'],
  ['00000000-0000-0000-0000-00000000000b', 'ben@lsi.test', 'Ben Manager', 'release_manager'],
  ['00000000-0000-0000-0000-0000000000ad', 'admin@lsi.test', 'Ada Admin', 'admin'],
];
const PASSWORD = 'password';

const db = new PGlite();
await db.exec(sql('tests/supabase-stub.sql'));
for (const file of readdirSync(join(root, 'supabase/migrations')).sort()) await db.exec(sql(`supabase/migrations/${file}`));
await db.exec(sql('supabase/seed.sql'));
for (const [id, email, name, role] of USERS) {
  await db.query('insert into auth.users (id, email) values ($1, $2)', [id, email]);
  await db.query('insert into lsicorp.staff (user_id, display_name, role) values ($1, $2, $3)', [id, name, role]);
}
// WITH_SYNC=1 also applies supabase/sync/*.sql, so the stand-in has the published
// releases of the live site and the download and launch buttons can be tried.
if (process.env.WITH_SYNC) {
  for (const file of readdirSync(join(root, 'supabase/sync')).sort()) await db.exec(sql(`supabase/sync/${file}`));
}
// A host that release files can be "served" from in local testing.
await db.exec(`update lsicorp.site_settings set allowed_external_domains = array_append(allowed_external_domains, 'downloads.lsi.test')`);

/** table -> { column -> SQL type } */
const tables = {};
for (const row of (
  await db.query(`
    select c.relname as table, a.attname as column, format_type(a.atttypid, a.atttypmod) as type
    from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'lsicorp' and c.relkind = 'r' and a.attnum > 0 and not a.attisdropped`)
).rows) {
  (tables[row.table] ??= {})[row.column] = row.type;
}

class HttpError extends Error {
  constructor(status, message, code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const ident = (name) => `"${name}"`;

/** Turns PostgREST query parameters into a WHERE clause, ORDER BY and LIMIT. */
function parseQuery(table, params, values) {
  const columns = tables[table];
  const where = [];
  let order = '';
  let limit = '';
  for (const [key, raw] of params) {
    if (key === 'select') continue;
    if (key === 'limit') {
      limit = ` limit ${Number(raw) | 0}`;
      continue;
    }
    if (key === 'order') {
      order =
        ' order by ' +
        raw
          .split(',')
          .map((part) => {
            const [column, direction] = part.split('.');
            if (!columns[column]) throw new HttpError(400, `Unknown column "${column}"`);
            return `${ident(column)} ${direction === 'desc' ? 'desc' : 'asc'}`;
          })
          .join(', ');
      continue;
    }
    if (!columns[key]) throw new HttpError(400, `Unknown column "${key}"`);
    const [, op, operand] = raw.match(/^(eq|in|is)\.(.*)$/s) ?? [];
    if (op === 'eq') {
      values.push(operand);
      where.push(`${ident(key)} = $${values.length}::${columns[key]}`);
    } else if (op === 'in') {
      values.push(operand.replace(/^\(|\)$/g, '').split(','));
      where.push(`${ident(key)}::text = any($${values.length}::text[])`);
    } else if (op === 'is' && ['true', 'false', 'null'].includes(operand)) {
      where.push(`${ident(key)} is ${operand}`);
    } else {
      throw new HttpError(400, `Unsupported filter "${raw}"`);
    }
  }
  return { where: where.length ? ` where ${where.join(' and ')}` : '', order, limit };
}

/** "$n::type" placeholders for the given columns of a JSON body. */
function bind(table, body, values) {
  const columns = tables[table];
  return Object.keys(body).map((column) => {
    const type = columns[column];
    if (!type) throw new HttpError(400, `Unknown column "${column}"`);
    const value = body[column];
    values.push(type === 'jsonb' && value !== null ? JSON.stringify(value) : value);
    return { column, placeholder: `$${values.length}::${type}` };
  });
}

async function rest(method, table, params, body, user, minimal) {
  if (!tables[table]) throw new HttpError(404, `Unknown table "${table}"`);
  const values = [];
  let statement;
  // "Prefer: return=minimal": write without reading the row back, which is
  // what lets a visitor who may insert but not select send an enquiry.
  if (method === 'POST' && minimal) {
    const bound = bind(table, body, values);
    statement = `insert into lsicorp.${ident(table)} (${bound.map((b) => ident(b.column)).join(', ')}) values (${bound.map((b) => b.placeholder).join(', ')})`;
    return db.transaction(async (tx) => {
      await tx.query(`select set_config('request.jwt.claim.sub', $1, true)`, [user ?? '']);
      await tx.exec(`set local role ${user ? 'authenticated' : 'anon'}`);
      await tx.query(statement, values);
      return [];
    });
  }
  if (method === 'GET') {
    const q = parseQuery(table, params, values);
    statement = `select coalesce(jsonb_agg(to_jsonb(t)), '[]') as rows from (select * from lsicorp.${ident(table)}${q.where}${q.order}${q.limit}) t`;
  } else if (method === 'POST') {
    const bound = bind(table, body, values);
    statement = `with changed as (insert into lsicorp.${ident(table)} (${bound.map((b) => ident(b.column)).join(', ')})
      values (${bound.map((b) => b.placeholder).join(', ')}) returning *)
      select coalesce(jsonb_agg(to_jsonb(changed)), '[]') as rows from changed`;
  } else if (method === 'PATCH') {
    const bound = bind(table, body, values);
    const q = parseQuery(table, params, values);
    if (!q.where) throw new HttpError(400, 'A filter is required');
    statement = `with changed as (update lsicorp.${ident(table)} set ${bound.map((b) => `${ident(b.column)} = ${b.placeholder}`).join(', ')}${q.where} returning *)
      select coalesce(jsonb_agg(to_jsonb(changed)), '[]') as rows from changed`;
  } else if (method === 'DELETE') {
    const q = parseQuery(table, params, values);
    if (!q.where) throw new HttpError(400, 'A filter is required');
    statement = `with changed as (delete from lsicorp.${ident(table)}${q.where} returning *)
      select coalesce(jsonb_agg(to_jsonb(changed)), '[]') as rows from changed`;
  } else {
    throw new HttpError(405, 'Method not allowed');
  }

  return db.transaction(async (tx) => {
    await tx.query(`select set_config('request.jwt.claim.sub', $1, true)`, [user ?? '']);
    await tx.exec(`set local role ${user ? 'authenticated' : 'anon'}`);
    return (await tx.query(statement, values)).rows[0].rows;
  });
}

function session(id) {
  const user = USERS.find((u) => u[0] === id);
  if (!user) throw new HttpError(400, 'Invalid login credentials');
  return { access_token: `mock.${id}`, refresh_token: `mock.${id}`, token_type: 'bearer', expires_in: 3600, user: { id, email: user[1] } };
}

function auth(path, params, body) {
  if (path === '/auth/v1/logout') return null;
  if (path === '/auth/v1/token' && params.get('grant_type') === 'password') {
    const user = USERS.find((u) => u[1] === String(body.email).toLowerCase());
    if (!user || body.password !== PASSWORD) throw new HttpError(400, 'Invalid login credentials');
    return session(user[0]);
  }
  if (path === '/auth/v1/token' && params.get('grant_type') === 'refresh_token') {
    return session(String(body.refresh_token).replace(/^mock\./, ''));
  }
  throw new HttpError(404, 'Not found');
}

createServer(async (request, response) => {
  const send = (status, data) => {
    response.writeHead(status, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'apikey, authorization, content-type, prefer, accept-profile, content-profile',
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    });
    response.end(data === undefined ? '' : JSON.stringify(data));
  };
  if (request.method === 'OPTIONS') return send(204);

  try {
    const url = new URL(request.url, 'http://localhost');
    let text = '';
    for await (const chunk of request) text += chunk;
    const body = text ? JSON.parse(text) : {};
    const token = (request.headers.authorization ?? '').replace(/^Bearer /, '');
    const user = token.startsWith('mock.') ? token.slice(5) : null;

    if (url.pathname.startsWith('/auth/v1/')) return send(200, auth(url.pathname, url.searchParams, body));
    if (url.pathname.startsWith('/rest/v1/')) {
      // The real API serves this schema only when the request names it.
      const profile = request.headers['accept-profile'] ?? request.headers['content-profile'];
      if (profile !== 'lsicorp') throw new HttpError(406, 'The schema must be one of the following: public, lsicorp. Send Accept-Profile or Content-Profile: lsicorp');
      const minimal = /return=minimal/.test(request.headers.prefer ?? '');
      const rows = await rest(request.method, url.pathname.slice('/rest/v1/'.length), url.searchParams, body, user, minimal);
      console.log(`${request.method} ${url.pathname}${url.search} as ${user ? USERS.find((u) => u[0] === user)?.[1] : 'visitor'} -> ${rows.length} row(s)`);
      return send(request.method === 'POST' ? 201 : 200, rows);
    }
    throw new HttpError(404, 'Not found');
  } catch (error) {
    // PostgREST reports a permission failure as 401/403 and a rule violation as 400.
    const denied = /permission denied|row-level security/.test(error.message);
    const status = error.status ?? (denied ? 403 : 400);
    console.log(`${request.method} ${request.url} -> ${status} ${error.message}`);
    send(status, { message: error.message, code: error.code ?? null });
  }
}).listen(port, () => console.log(`Mock Supabase listening on http://localhost:${port}`));
