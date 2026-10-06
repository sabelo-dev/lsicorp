// Turns the authored files in content/ into the two seed files:
//   supabase/seed.sql   first-time content for a new Supabase project
//   app/seed/seed.json  the same rows, bundled into the app as preview data
//                       for when no Supabase project is configured
// Rows use the database column names, so the app reads one shape everywhere.
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkMarkdown, checkProductLink } from '../app/qml/rules.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const content = join(root, 'content');
const readJson = (path) => JSON.parse(readFileSync(path, 'utf8'));
const files = (dir, ext) =>
  readdirSync(join(content, dir), { withFileTypes: true })
    .filter((f) => f.isFile() && f.name.endsWith(ext))
    .map((f) => join(content, dir, f.name))
    .sort();
const folders = (dir) =>
  readdirSync(join(content, dir), { withFileTypes: true })
    .filter((f) => f.isDirectory())
    .map((f) => f.name)
    .sort();

/** Splits "---\nkey: value\n---\nbody" into its fields and body. */
function readMarkdown(path) {
  const match = readFileSync(path, 'utf8').replace(/\r\n/g, '\n').match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) throw new Error(`${path}: missing front matter`);
  const fields = {};
  for (const line of match[1].split('\n')) {
    const at = line.indexOf(':');
    if (at < 1) throw new Error(`${path}: cannot read front matter line "${line}"`);
    fields[line.slice(0, at).trim()] = line.slice(at + 1).trim();
  }
  return { fields, body: match[2].trim() + '\n' };
}

const problems = [];
const need = (where, object, keys) => {
  for (const key of keys) if (object[key] === undefined || object[key] === '') problems.push(`${where}: "${key}" is required`);
};

const site = readJson(join(content, 'site.json'));
const allowed = site.allowedExternalDomains;

const seed = {
  site_settings: [
    {
      id: true,
      name: site.name,
      organisation: site.organisation,
      short_name: site.shortName,
      description: site.description,
      tagline: site.tagline,
      date_timezone: site.dateTimezone,
      contact_email: site.contact.email,
      contact_phone: site.contact.phone,
      location: site.contact.location,
      support_email: site.support.email,
      support_url: site.support.url,
      allowed_external_domains: allowed,
    },
  ],
  services: files('services', '.json').map((path) => {
    const slug = basename(path, '.json');
    const service = readJson(path);
    need(`services/${slug}`, service, ['name', 'mark', 'tagline', 'summary']);
    return {
      slug,
      name: service.name,
      mark: service.mark,
      tagline: service.tagline,
      summary: service.summary,
      offerings: service.offerings,
      sort_order: service.order,
    };
  }),
  products: files('products', '.json').map((path) => {
    const slug = basename(path, '.json');
    const p = readJson(path);
    need(`products/${slug}`, p, ['publicName', 'internalName', 'mark', 'tagline', 'summary', 'category', 'status', 'statusNote', 'gettingStarted']);
    for (const link of [p.supportUrl, p.privacyUrl]) {
      if (link) problems.push(...checkProductLink(link, allowed).map((m) => `products/${slug}: ${m}`));
    }
    return {
      slug,
      public_name: p.publicName,
      internal_name: p.internalName,
      mark: p.mark,
      tagline: p.tagline,
      summary: p.summary,
      category: p.category,
      sort_order: p.order,
      status: p.status,
      status_note: p.statusNote,
      audiences: p.audiences,
      capabilities: p.capabilities,
      requirements: p.requirements,
      services: p.services,
      platforms: p.platforms,
      platform_note: p.platformNote ?? null,
      getting_started: p.gettingStarted,
      limitations: p.limitations,
      notice_title: p.notice?.title ?? null,
      notice_body: p.notice?.body ?? null,
      support_url: p.supportUrl,
      privacy_url: p.privacyUrl,
      icon_path: p.icon,
    };
  }),
  doc_pages: folders('docs').flatMap((product) =>
    files(`docs/${product}`, '.md').map((path) => {
      const { fields, body } = readMarkdown(path);
      const where = `docs/${product}/${basename(path)}`;
      need(where, fields, ['title', 'summary', 'audience', 'order', 'lastReviewed', 'status']);
      problems.push(...checkMarkdown(body, allowed).map((m) => `${where}: ${m}`));
      return {
        product_slug: product,
        slug: basename(path, '.md'),
        title: fields.title,
        summary: fields.summary,
        audience: fields.audience,
        sort_order: Number(fields.order),
        body,
        last_reviewed: fields.lastReviewed,
        status: fields.status,
      };
    }),
  ),
  faqs: files('faqs', '.json').flatMap((path) =>
    readJson(path).items.map((item, index) => ({
      product_slug: basename(path, '.json'),
      question: item.question,
      answer: item.answer,
      category: item.category,
      escalation: item.escalation ?? null,
      visible: item.visible,
      sort_order: index + 1,
    })),
  ),
  pages: files('pages', '.md').map((path) => {
    const { fields, body } = readMarkdown(path);
    const where = `pages/${basename(path)}`;
    need(where, fields, ['title', 'description', 'lastReviewed']);
    problems.push(...checkMarkdown(body, allowed).map((m) => `${where}: ${m}`));
    return { slug: basename(path, '.md'), title: fields.title, description: fields.description, body, last_reviewed: fields.lastReviewed };
  }),
  // Releases are never seeded: each one is drafted, reviewed and published by staff.
  releases: [],
  // Enquiries come from visitors.
};

const serviceSlugs = new Set(seed.services.map((service) => service.slug));
for (const product of seed.products) {
  for (const service of product.services) {
    if (!serviceSlugs.has(service)) problems.push(`products/${product.slug}: unknown service "${service}"`);
  }
}
const slugs = new Set(seed.products.map((p) => p.slug));
for (const row of [...seed.doc_pages, ...seed.faqs]) {
  if (!slugs.has(row.product_slug)) problems.push(`content for unknown product "${row.product_slug}"`);
}
if (problems.length) {
  console.error(`Content has problems:\n- ${problems.join('\n- ')}`);
  process.exit(1);
}

const text = (value) => `'${String(value).replaceAll("'", "''")}'`;
function literal(value) {
  if (value === null || value === undefined) return 'null';
  if (typeof value === 'boolean' || typeof value === 'number') return String(value);
  if (Array.isArray(value) && value.every((v) => typeof v === 'string')) {
    return value.length ? `array[${value.map(text).join(', ')}]::text[]` : `'{}'::text[]`;
  }
  if (typeof value === 'object') return `${text(JSON.stringify(value))}::jsonb`;
  return text(value);
}
// jsonb columns must stay jsonb even when the array happens to hold only strings.
const JSONB = new Set(['audiences', 'capabilities', 'requirements']);
function insert(table, rows, conflict) {
  return rows
    .map((row) => {
      const columns = Object.keys(row);
      const values = columns.map((c) => (JSONB.has(c) ? `${text(JSON.stringify(row[c]))}::jsonb` : literal(row[c])));
      return `insert into lsicorp.${table} (${columns.join(', ')})\nvalues (${values.join(', ')})\non conflict (${conflict}) do nothing;\n`;
    })
    .join('\n');
}

const sql = `-- Generated by scripts/build-seed.mjs from content/. Do not edit by hand.
-- First-time content for a new project. Rows that already exist are left
-- alone, so running this again never overwrites edits made by staff.

${insert('site_settings', seed.site_settings, 'id')}
${insert('services', seed.services, 'slug')}
${insert('products', seed.products, 'slug')}
${insert('doc_pages', seed.doc_pages, 'product_slug, slug')}
${insert('pages', seed.pages, 'slug')}
-- FAQs have no natural key, so they are only added to an empty table.
do $$
begin
  if not exists (select 1 from lsicorp.faqs) then
${seed.faqs
  .map((row) => {
    const columns = Object.keys(row);
    return `    insert into lsicorp.faqs (${columns.join(', ')}) values (${columns.map((c) => literal(row[c])).join(', ')});`;
  })
  .join('\n')}
  end if;
end
$$;
`;

mkdirSync(join(root, 'app', 'seed'), { recursive: true });
writeFileSync(join(root, 'supabase', 'seed.sql'), sql);
writeFileSync(join(root, 'app', 'seed', 'seed.json'), JSON.stringify(seed, null, 1) + '\n');
console.log(
  `Seed written: ${seed.services.length} services, ${seed.products.length} products, ${seed.doc_pages.length} documentation pages, ${seed.faqs.length} FAQs, ${seed.pages.length} pages.`,
);
