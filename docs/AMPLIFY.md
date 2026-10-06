# Deploying to AWS Amplify Hosting

The site is static files, which Amplify Hosting serves through CloudFront. There are two ways to
get them there. Start with the manual deploy: it uses a build you have already tested locally.

## What the build does for Amplify

`scripts/package.mjs` (run automatically at the end of a build) arranges `dist/` for CloudFront:

- **Compressed module.** CloudFront does not compress files larger than 10 MB, and the app's
  WebAssembly module is about 26 MB. The build writes a gzip copy (about 9 MB) and the page
  downloads and unpacks that copy itself, with a progress bar. Browsers without the needed
  feature fall back to the uncompressed file.
- **Content-hashed names.** The module and its script are named after their contents
  (`app.<hash>.wasm.gz`), so `customHttp.yml` can let browsers and CloudFront keep them for a
  year, and a new deploy is picked up immediately because the names change.
- **Per-environment settings.** `config.js` is written from the `SUPABASE_URL` and
  `SUPABASE_ANON_KEY` environment variables, and `robots.txt` blocks search engines unless
  `SITE_ENV` is `production`.

No rewrite or redirect rules are needed: pages are addressed by URL fragment (`/#/products`),
so every address loads `index.html`.

## Option A: manual deploy (verified locally)

1. Build with the environment's settings:

   ```powershell
   $env:SUPABASE_URL = 'https://<ref>.supabase.co'
   $env:SUPABASE_ANON_KEY = '<anon key>'
   $env:SITE_ENV = 'production'        # or 'staging'
   scripts\build-wasm.ps1
   npm run serve                       # check it at http://localhost:8080
   Compress-Archive -Path dist\* -DestinationPath site.zip -Force
   ```

2. In the Amplify console: **Create new app > Deploy without Git**, name the app and branch, and
   upload `site.zip`.
3. **Hosting > Custom headers**: paste the contents of `customHttp.yml` and save.
4. **Hosting > Custom domains**: add the production domain. Amplify issues the certificate and
   redirects HTTP to HTTPS.

To update the site, repeat step 1 and upload the new zip to the same branch.

## Option B: Git-connected build (not yet run on Amplify)

`amplify.yml` builds the site on Amplify itself: it installs Qt and Emscripten into a cached
`.toolchain/` folder (`scripts/amplify-toolchain.sh`), builds (`scripts/build-wasm.sh`) and
publishes `dist/`. `customHttp.yml` is picked up from the repository root automatically.

1. Push this repository to GitHub, CodeCommit, GitLab or Bitbucket and connect it in the Amplify
   console.
2. Under **Environment variables**, set `SUPABASE_URL` and `SUPABASE_ANON_KEY`, with per-branch
   overrides so that `main` points at the production Supabase project and other branches at
   staging.
3. Deploy. The first build downloads the toolchain and takes several minutes; later builds reuse
   the cache.

This path has not been executed on Amplify. The build scripts mirror the Windows build that was
tested, but the Linux toolchain install is the part most likely to need adjusting on first run
(for example a missing system library in the build image). If it fails, use Option A while it is
sorted out.

Only `main` is treated as production (indexable). Change the branch name in `amplify.yml` if
production deploys from a different branch.

## Staging

Use a separate Amplify branch (or app) with the staging Supabase project's variables. With
`SITE_ENV` set to anything other than `production`, the build writes a `robots.txt` that blocks
indexing. For a private staging site, also turn on **Access control** for that branch in the
Amplify console.

## Rollback

In the Amplify console, open the branch's deployment history and choose **Redeploy this version**
on the last good deployment. Content lives in Supabase and is unaffected by a site rollback.

## Checks after each deploy

- The site loads and the footer does **not** say "Preview data" (which would mean `config.js`
  has no Supabase settings).
- In the browser's network panel: the `.wasm.gz` file returns
  `Cache-Control: public, max-age=31536000, immutable`, and `index.html` and `config.js` return
  `no-cache`.
- The browser console shows no Content-Security-Policy errors. If the Supabase project uses a
  custom domain, update `connect-src` in `customHttp.yml`.
