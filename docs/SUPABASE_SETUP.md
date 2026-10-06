# Supabase setup

The site keeps its content in Supabase. It **shares the 1145 project** (`hipomusjocacncjsvgfa`)
rather than having a project of its own.

## How the site coexists with 1145

- Everything the site owns is in a separate Postgres schema, **`lsicorp`**. It creates no tables
  or functions in `public`, and changes no grants there.
- It adds one storage bucket, `lsicorp-release-files`, and three policies on `storage.objects`
  whose names start with `lsicorp:`.
- It is installed from a single SQL file, **outside 1145's migration history**. 1145's
  `supabase db push`, `db diff` and generated types look at `public` and are unaffected.
- **Sign-in is shared.** The site's staff are ordinary users of the project who also have a row
  in `lsicorp.staff`. Every 1145 customer is a signed-in user as far as the database is
  concerned, so nothing in `lsicorp` is granted on the strength of being signed in: staff-only
  access always checks `lsicorp.staff`.

`npm test` checks all of this against a real Postgres engine, including that another
application's table in the same database is left exactly as it was.

## 1. Install the schema

`supabase/install.sql` is generated from the migrations and the seed (`npm run seed` rebuilds
it). It runs in one transaction and refuses to run if the `lsicorp` schema already exists.

**This was run on the 1145 project on 6 October 2026.** On another project, in the Supabase
dashboard: **SQL Editor > New query**, paste the whole of `supabase/install.sql`, and run it.

It creates the tables, rules and security policies, and loads the starting content: site
settings, four services, the four portfolio items with their documentation and FAQs, and the
policy pages. It loads **no releases** and no staff.

To remove everything again: `supabase/uninstall.sql`. That deletes all of the site's content.

## 2. Expose the schema to the API

The API only serves schemas it has been told about. Until `lsicorp` is one of them, the site
shows "Content is unavailable" with a message that the schema must be one of the exposed ones.

**On the 1145 project this was done on 6 October 2026 with SQL**, as a setting on the API's
database role:

```sql
alter role authenticator set pgrst.db_schemas = 'public, graphql_public, lsicorp';
notify pgrst, 'reload config';
```

A setting made this way **takes precedence over the dashboard's "Exposed schemas" box**
(Project Settings > API). If someone later changes that box and nothing happens, this is why.
To add or remove a schema, run the statement again with the full list. To hand control back to
the dashboard, add `lsicorp` to the dashboard box first, then run:

```sql
alter role authenticator reset pgrst.db_schemas;
notify pgrst, 'reload config';
```

On a different project, the dashboard box alone is enough.

## 3. Create the first administrator

Use an existing account or create one under **Authentication > Users**, and copy its UID. Then
in the SQL editor:

```sql
insert into lsicorp.staff (user_id, display_name, role)
values ('00000000-0000-0000-0000-000000000000', 'Full Name', 'admin');
```

Further staff are added from the site (Staff tab) using their UID. At least **two** people need
the release manager or administrator role, because a release cannot be approved by the person
who prepared it.

Do not turn off public sign-up for the project on the site's account: 1145's customers need it.
It does not matter for the site, since being signed in grants nothing by itself.

## 4. Connect the site

The site needs the project URL and the **anon (publishable) key**. Both are public by design;
row-level security decides what the key can do. Never use the service-role key.

- **Local build:** put them in a `.env` file in the repository root (it is git-ignored) and build.

  ```
  SUPABASE_URL=https://hipomusjocacncjsvgfa.supabase.co
  SUPABASE_ANON_KEY=<anon key>
  ```

- **AWS Amplify:** set the same two names as environment variables (see [AMPLIFY.md](AMPLIFY.md)).

The build writes them into `config.js`. When the site is connected, the "Preview data" line in
its footer disappears and Staff sign-in starts working.

## 5. Allow the domains you will link to

Site settings > Allowed external domains lists every host a download, launch or content link may
point to. It starts with `play.google.com`, `apps.apple.com` and `1145.io`. Add
`hipomusjocacncjsvgfa.supabase.co` if release files will be served from the
`lsicorp-release-files` bucket.

## Roles

| Role | Can do |
| --- | --- |
| Content editor | Edit services, work, documentation, FAQs and pages. Read and handle enquiries. |
| Release manager | Everything an editor can, plus draft, submit, approve, supersede and withdraw releases, and upload release files. |
| Administrator | Everything, plus site settings, staff and roles, and deleting records. |

Deactivate a person (Staff > untick Active) rather than deleting them, so release records keep
showing who prepared and approved them.

## Changing the schema later

Add a new file to `supabase/migrations/` and apply that file's SQL to the project by hand, the
same way. Do not `supabase db push` from this repository: the project's migration history
belongs to 1145.
