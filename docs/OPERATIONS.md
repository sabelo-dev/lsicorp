# Operations

Deployment, environments, backup, rollback and monitoring, and where this build departs from
the original specification.

## Deployment

The site is hosted on AWS Amplify Hosting. See [AMPLIFY.md](AMPLIFY.md) for the two ways to
deploy, the response headers (`customHttp.yml`), staging and rollback.

In short: `scripts\build-wasm.ps1` (Windows) or `scripts/build-wasm.sh` (Linux, macOS) builds
the app and writes the deployable files to `dist\`. `npm run serve` serves that folder locally
with the production headers, so a policy problem shows up before deployment.

The production domain has not been chosen yet; confirm it before launch.

## Environments

Keep two Supabase projects and two site deployments: staging and production. Staging must not be
indexed: replace its `robots.txt` with `Disallow: /` and add an `X-Robots-Tag: noindex` header.
Try schema changes and unusual content on staging first.

## Backup and restore

All content and release records are in the Supabase database.

- Supabase takes automatic daily backups on paid plans; point-in-time recovery is an add-on.
  Check which your plan includes.
- For an independent copy: `supabase db dump --data-only -f backup.sql` (and without
  `--data-only` for the schema). Store dumps somewhere other than Supabase.
- Restore: on a new or reset project, apply the migrations, then run the data dump. Auth users
  are restored by Supabase's own backup, not by a data dump of the `public` schema; after a
  manual restore, recreate staff sign-ins and re-point `staff.user_id` if the UIDs changed.
- Release files in the `release-files` bucket are not in database backups. Keep the original
  build artefacts wherever builds are archived.

Practise a restore into a scratch project before launch. This has not been done yet.

## Rollback

| What went wrong | How to roll back |
| --- | --- |
| A bad site build | In the Amplify console, redeploy the last good deployment. Content is unaffected. |
| A bad content edit | Open the record's entry in the Audit log to see the previous values and re-enter them. |
| A bad release | Withdraw it (with a reason), or publish the corrected version, which supersedes it. |
| A bad schema change | Write a new migration that reverses it. Restore from backup only if data was lost. |

## Monitoring

- `scripts/verify-releases.mjs` fetches every published destination and, for direct files,
  re-hashes the served file against the recorded checksum. The workflow in
  `.github/workflows/verify-releases.yml` runs it daily and fails when something is wrong;
  set the `SUPABASE_URL` and `SUPABASE_ANON_KEY` repository secrets and make sure the site owner
  receives failure notifications.
- Add an uptime check on the site address with any monitoring service.
- Supabase's dashboard has the API and auth logs, including failed sign-ins and refused writes.

## Privacy and analytics

No analytics or tracking is embedded, and the public pages collect nothing. If measurement is
wanted later, choose a privacy-conscious tool, get the product owner's approval for purpose,
consent wording and retention, and update the privacy notice first.

## Departures from the original specification

The specification was written for a conventional website. Building the public site as a Qt Quick
WebAssembly application, as later requested, means these criteria are **not met**:

| Specification item | Status | Why |
| --- | --- | --- |
| WCAG 2.2 AA | Partly. Keyboard operation, focus return, visible focus, contrast, text status labels, field-level form errors, announcements of results and outcomes, and reduced motion are in place (see [INTERACTION.md](INTERACTION.md)). Screen-reader support is limited and unverified. | The interface is drawn on a canvas. Qt exposes an accessibility tree to browsers, but coverage varies and it has not been tested with a screen reader. Browser zoom, find-in-page and reader mode do not behave as on normal pages. |
| Search: page titles, descriptions, canonical URLs, sitemap, structured product metadata | Not met. The page title updates per page and the host page has a description; nothing else. | Search engines see one HTML page with no content. Pages are addressed by URL fragment (`/#/products/1145`), which cannot have canonical URLs or a meaningful sitemap. |
| Lightweight pages | Not met. | A first visit downloads the whole application: about 9 MB compressed, cached for a year afterwards. |
| Clean routes (`/products/1145`) | Fragment routes (`/#/products/1145`). | Works on any static host without rewrite rules; see above for the cost. |
| Strong authentication for staff | Passwords, with public sign-up disabled. Multi-factor sign-in is not implemented in the app. | |
| Malware scanning of hosted binaries | Not provided. | Supabase Storage does not scan files. Scan builds before upload, or host binaries somewhere that does. |

If search visibility and accessibility matter for the public pages, the practical fix is a small
static HTML rendering of the same Supabase content for the public pages, keeping this
application for the staff area.

## Not yet verified

- Nothing has run against the real Supabase project. The schema, security rules and workflow were
  tested in an in-process Postgres with Supabase's auth and storage pieces stubbed
  (`npm test`), and the app was tested against `scripts/mock-supabase.mjs`.
- No deployment, backup restore or rollback has been rehearsed on a real host.
- The WebAssembly build was checked in headless Chrome only (`scripts/wheel-check.mjs`,
  `scripts/interaction-check.mjs`). Test current Firefox, Safari
  (including iOS) and Edge, real phones, and at least one screen reader before launch.
- Product statuses and target platforms in the starting content are conservative guesses from
  the specification and need confirming by each product owner.
- The privacy notice and terms are plain-language starting points and need legal review.
- Support contact details are empty; the Support page says so until they are filled in under
  Site settings.
