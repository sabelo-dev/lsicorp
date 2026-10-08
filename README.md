# LSI Corp website

The website of Lifestyle Investment Corp (LSI): a digital service provider working across
technology, logistics and finance. The site presents the company and its services first, and the
products LSI has built (1145 Lifestyle, 1145Hz Player, LSI Podcast and Online Radio, LSI Gold
Digger) as its portfolio, with their documentation and official downloads.
See [docs/SITE_SPEC.md](docs/SITE_SPEC.md) for the specification.

The site is a **Qt Quick (QML) application compiled to WebAssembly**. Its content lives in
**Supabase**, in its own `lsicorp` schema inside the project that also serves 1145, where
row-level security and database triggers enforce who may change what. Staff edit everything from
the site's own admin area; nobody edits page code to change a service, a portfolio item or a
download link.

## How it fits together

| Part | Where | What it does |
| --- | --- | --- |
| App | `app/` | The whole site: public pages and the staff admin area. QML in `app/qml`, a small C++ shell in `app/src`, the host page in `app/web`, logo and font in `app/assets`. |
| Database | `supabase/migrations/`, `supabase/install.sql` | Tables, staff roles, row-level security, the release workflow, enquiries and the audit log, all in the `lsicorp` schema. `install.sql` is the single file that installs it. |
| Starting content | `content/` | Site settings, the services, the four portfolio items with their documentation and FAQs, and the policy pages, as authored files. |
| Seed | `supabase/seed.sql`, `app/seed/seed.json` | Generated from `content/` by `npm run seed` (which also rebuilds `install.sql`). The SQL loads the starting content; the JSON is the preview data the app shows when no project is configured. |
| Hosting | `amplify.yml`, `customHttp.yml` | Build settings and response headers for AWS Amplify Hosting. |
| Brand | `brand/` | The source logo files. `python scripts/make-icons.py brand/lsi-corp-wordmark.png brand/lsi-mark.png` regenerates every logo and icon the site uses. |
| Tooling | `scripts/`, `tests/` | Seed generator, tests, a local stand-in for Supabase, a local web server, and a checker for published download links. |

Shared rules (what counts as a safe link, which release is "current", what a button may say) are
in one file, `app/qml/rules.mjs`, used by both the app and the tooling. The database enforces the
same rules independently.

## Prerequisites

- Node.js 22 or newer (tooling and tests only).
- To build the site: Qt 6.12 with the **WebAssembly (single-threaded)** kit and a desktop kit of
  the same version, plus Emscripten 5.0.5 (the version Qt 6.12 expects).

## Quick start

```powershell
npm install
npm test                      # rules + database (migrations, security, release workflow)

# Build the site
scripts\build-wasm.ps1        # the deployable site is written to dist\
npm run serve                 # serves dist\ at http://localhost:8080, with production security headers
```

With nothing configured, the site runs on the bundled preview data and says so in its footer.

### Try it with a database, without a Supabase project

```powershell
node scripts/mock-supabase.mjs    # local stand-in on http://localhost:54321, real migrations
```

Set `supabaseUrl: 'http://localhost:54321'` and `supabaseKey: 'anon'` in `dist\config.js`,
reload, and sign in at `/#/admin` as `editor@lsi.test`, `ann@lsi.test`, `ben@lsi.test` (release
managers) or `admin@lsi.test`, password `password`. Data resets each time the stand-in starts.

Start it with `WITH_SYNC=1` to include the releases published on the live site, so that download
and launch buttons appear. With that and `npm run serve` running,
`node scripts/interaction-check.mjs` drives headless Chrome through the keyboard, search, form
and download interactions and saves a screenshot of each step.

### Desktop build for development

```powershell
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;C:\Qt\Tools\CMake_64\bin;$env:PATH"
cmake -S app -B build/desktop -G Ninja -DCMAKE_PREFIX_PATH=C:\Qt\6.12.0\mingw_64 -DCMAKE_BUILD_TYPE=Release
cmake --build build/desktop
scripts\shot.ps1 -Route /products/1145 -Out page.png     # render any page to an image
```

## Configuration

There are no secrets in this repository or in the built site.

| Name | Where it is set | Purpose |
| --- | --- | --- |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Environment of the build (Amplify environment variables) | Written into `config.js` by the build. Leave unset to keep the template. |
| `SITE_ENV` | Environment of the build | `production` allows search indexing; any other value blocks it. Set from the branch name by `amplify.yml`. |
| `supabaseUrl` | `config.js` next to the built site | The Supabase project URL. |
| `supabaseKey` | `config.js` next to the built site | The project's public anon (publishable) key. Never the service-role key. |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Environment of `scripts/verify-releases.mjs` (CI secrets) | Same two values, for the scheduled link check. |
| `LSI_SUPABASE_URL`, `LSI_SUPABASE_KEY` | Environment of a desktop build | Same two values, for local development. |
| `PORT` | Environment of `scripts/mock-supabase.mjs` | Port for the local stand-in (default 54321). |

## More documentation

- [docs/SITE_SPEC.md](docs/SITE_SPEC.md): what the site is for and what it must do.
- [docs/INTERACTION.md](docs/INTERACTION.md): how controls behave: states, keyboard, feedback, motion, and what was checked.
- [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md): installing into the shared 1145 project, exposing the schema, the first administrator.
- [docs/CONTENT_AND_RELEASES.md](docs/CONTENT_AND_RELEASES.md): editing content, the release checklist, an admin walkthrough.
- [docs/AMPLIFY.md](docs/AMPLIFY.md): deploying to AWS Amplify Hosting.
- [docs/OPERATIONS.md](docs/OPERATIONS.md): deployment, staging, backup and restore, rollback, monitoring, and where the site departs from the original specification.
