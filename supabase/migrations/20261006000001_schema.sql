-- LSI Corp website: content tables, staff roles and the audit log.
-- Access rules are in 20261006000003_security.sql.
--
-- Everything lives in its own "lsicorp" schema, so the site can share a
-- Supabase project with another application (it shares the 1145 project)
-- without touching that application's tables, grants or migration history.

create schema if not exists lsicorp;

create table lsicorp.staff (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (length(trim(display_name)) > 0),
  role text not null check (role in ('editor', 'release_manager', 'admin')),
  -- Staff are deactivated rather than deleted so that release records keep
  -- pointing at the person who prepared or reviewed them.
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table lsicorp.site_settings (
  id boolean primary key default true check (id),
  name text not null,
  organisation text not null,
  short_name text not null,
  description text not null,
  tagline text not null default '',
  date_timezone text not null default 'UTC',
  contact_email text,
  contact_phone text,
  location text,
  support_email text,
  support_url text,
  -- The only hosts a download, launch or content link may point to.
  allowed_external_domains text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- What LSI Corp offers. The portfolio (products) is linked to these.
create table lsicorp.services (
  slug text primary key check (slug ~ '^[a-z0-9][a-z0-9-]*$'),
  name text not null check (length(trim(name)) > 0),
  mark text not null check (length(mark) between 1 and 4),
  tagline text not null,
  summary text not null,
  offerings text[] not null default '{}',
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);

-- The portfolio: each product is a piece of work by LSI Corp.
create table lsicorp.products (
  slug text primary key check (slug ~ '^[a-z0-9][a-z0-9-]*$'),
  public_name text not null check (length(trim(public_name)) > 0),
  internal_name text not null check (length(trim(internal_name)) > 0),
  mark text not null check (length(mark) between 1 and 4),
  tagline text not null,
  summary text not null,
  category text not null,
  sort_order integer not null default 0,
  status text not null check (status in ('available', 'in-development', 'coming-soon', 'maintenance')),
  status_note text not null,
  audiences jsonb not null default '[]' check (jsonb_typeof(audiences) = 'array'),
  capabilities jsonb not null default '[]' check (jsonb_typeof(capabilities) = 'array'),
  requirements jsonb not null default '[]' check (jsonb_typeof(requirements) = 'array'),
  -- Slugs of the services this work demonstrates.
  services text[] not null default '{}',
  platforms text[] not null default '{}'
    check (platforms <@ array['android', 'ios', 'web', 'windows', 'macos', 'linux', 'other']),
  platform_note text,
  getting_started text not null,
  limitations text[] not null default '{}',
  notice_title text,
  notice_body text,
  support_url text,
  privacy_url text,
  icon_path text,
  updated_at timestamptz not null default now(),
  check ((notice_title is null) = (notice_body is null))
);

create table lsicorp.doc_pages (
  id uuid primary key default gen_random_uuid(),
  product_slug text not null references lsicorp.products (slug) on update cascade on delete cascade,
  slug text not null check (slug ~ '^[a-z0-9][a-z0-9-]*$'),
  title text not null check (length(trim(title)) > 0),
  summary text not null,
  audience text not null,
  sort_order integer not null default 0,
  body text not null,
  last_reviewed date not null default current_date,
  status text not null default 'draft' check (status in ('draft', 'published')),
  updated_at timestamptz not null default now(),
  unique (product_slug, slug)
);

create table lsicorp.faqs (
  id uuid primary key default gen_random_uuid(),
  product_slug text not null references lsicorp.products (slug) on update cascade on delete cascade,
  question text not null check (length(trim(question)) > 0),
  answer text not null,
  category text not null,
  escalation text,
  visible boolean not null default false,
  sort_order integer not null default 0,
  updated_at timestamptz not null default now()
);

-- About and policy pages.
create table lsicorp.pages (
  slug text primary key check (slug ~ '^[a-z0-9][a-z0-9-]*$'),
  title text not null check (length(trim(title)) > 0),
  description text not null,
  body text not null,
  last_reviewed date not null default current_date,
  updated_at timestamptz not null default now()
);

create table lsicorp.releases (
  id uuid primary key default gen_random_uuid(),
  product_slug text not null references lsicorp.products (slug) on update cascade on delete restrict,
  platform text not null check (platform in ('android', 'ios', 'web', 'windows', 'macos', 'linux', 'other')),
  version text not null check (version ~ '^[0-9A-Za-z][0-9A-Za-z.-]*$'),
  channel text not null default 'stable' check (channel in ('stable', 'beta', 'preview')),
  status text not null default 'draft'
    check (status in ('draft', 'in-review', 'available', 'superseded', 'withdrawn')),
  release_date date not null,
  destination_type text not null check (destination_type in ('store', 'web-app', 'file')),
  destination_url text not null,
  artifact_filename text,
  artifact_file_type text,
  artifact_size_bytes bigint check (artifact_size_bytes > 0),
  artifact_sha256 text check (artifact_sha256 ~ '^[0-9a-f]{64}$'),
  compat_minimum text not null,
  compat_device_class text not null,
  compat_dependencies text[] not null default '{}',
  steps text[] not null check (cardinality(steps) > 0),
  notes text[] not null check (cardinality(notes) > 0),
  known_issues text[] not null default '{}',
  licence text not null,
  support_route text not null,
  prepared_by uuid references lsicorp.staff (user_id) on delete restrict,
  reviewed_by uuid references lsicorp.staff (user_id) on delete restrict,
  reviewed_at timestamptz,
  superseded_by text,
  withdrawn_reason text,
  updated_at timestamptz not null default now(),
  unique (product_slug, platform, version),
  -- One live release per product, platform and channel. Deferred so that
  -- publishing a new version can supersede the old one in the same transaction.
  constraint one_available_release_per_channel
    exclude using btree (product_slug with =, platform with =, channel with =)
    where (status = 'available') deferrable initially deferred
);

create index releases_product_idx on lsicorp.releases (product_slug, release_date desc);

-- Messages sent through the contact form. Visitors can add one and nothing
-- else; only staff can read them.
create table lsicorp.enquiries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null check (length(trim(name)) between 1 and 120),
  email text not null check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and length(email) <= 200),
  organisation text check (length(organisation) <= 160),
  service_slug text references lsicorp.services (slug) on update cascade on delete set null,
  message text not null check (length(trim(message)) between 10 and 4000),
  -- The sender agreed to be contacted about this enquiry.
  consent boolean not null check (consent),
  status text not null default 'new' check (status in ('new', 'in-progress', 'closed')),
  notes text
);

create index enquiries_created_idx on lsicorp.enquiries (created_at desc);

-- Who changed what, and when. Rows are written only by the audit trigger.
create table lsicorp.audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  actor uuid,
  actor_name text,
  table_name text not null,
  record_key text not null,
  action text not null check (action in ('insert', 'update', 'delete')),
  old_data jsonb,
  new_data jsonb
);

create index audit_log_at_idx on lsicorp.audit_log (at desc);
