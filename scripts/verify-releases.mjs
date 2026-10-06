// Checks every published release the way a visitor would reach it:
//   - the destination is https and on the allowlist
//   - the destination answers successfully
//   - for a direct file, the size and SHA-256 of the served file match the record
// Exits with code 1 if anything fails, so a scheduled run can alert the site owner.
//
//   SUPABASE_URL=https://<ref>.supabase.co SUPABASE_ANON_KEY=<anon key> node scripts/verify-releases.mjs
import { createHash } from 'node:crypto';
import { checkExternalUrl, releasePath } from '../app/qml/rules.mjs';

const url = (process.env.SUPABASE_URL ?? '').replace(/\/+$/, '');
const key = process.env.SUPABASE_ANON_KEY ?? '';
if (!url || !key) {
  console.error('Set SUPABASE_URL and SUPABASE_ANON_KEY.');
  process.exit(2);
}

async function rows(table, query) {
  const response = await fetch(`${url}/rest/v1/${table}?${query}`, { headers: { apikey: key, 'Accept-Profile': 'lsicorp' } });
  if (!response.ok) throw new Error(`Could not read ${table}: ${response.status} ${await response.text()}`);
  return response.json();
}

const [settings] = await rows('site_settings', 'select=allowed_external_domains');
const releases = await rows('releases', 'select=*&status=eq.available');
const failures = [];

for (const release of releases) {
  const name = releasePath(release);
  const problems = checkExternalUrl(release.destination_url, settings.allowed_external_domains);
  if (problems.length === 0) {
    try {
      const response = await fetch(release.destination_url, { redirect: 'follow' });
      if (!response.ok) {
        problems.push(`destination answered ${response.status}`);
      } else if (release.destination_type === 'file') {
        const hash = createHash('sha256');
        let size = 0;
        for await (const chunk of response.body) {
          hash.update(chunk);
          size += chunk.length;
        }
        const digest = hash.digest('hex');
        if (size !== Number(release.artifact_size_bytes)) problems.push(`served file is ${size} bytes, record says ${release.artifact_size_bytes}`);
        if (digest !== release.artifact_sha256) problems.push(`served file has SHA-256 ${digest}, record says ${release.artifact_sha256}`);
      } else {
        await response.body?.cancel();
      }
    } catch (error) {
      problems.push(`destination could not be reached (${error.message})`);
    }
  }
  console.log(`${problems.length ? 'FAIL' : 'ok  '} ${name}`);
  for (const problem of problems) failures.push(`${name}: ${problem}`);
}

if (failures.length) {
  console.error(`\n${failures.length} problem(s):\n- ${failures.join('\n- ')}`);
  process.exit(1);
}
console.log(`\n${releases.length} published release(s) verified.`);
