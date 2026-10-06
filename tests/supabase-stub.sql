-- The parts of a Supabase project that our migrations rely on, reduced to the
-- minimum needed to run them in a plain Postgres for tests.

create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema auth;
create table auth.users (id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated;

create schema storage;
create table storage.buckets (id text primary key, name text not null, public boolean not null default false);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text
);
alter table storage.objects enable row level security;
grant usage on schema storage to anon, authenticated;
grant select, insert, update, delete on storage.objects to anon, authenticated;

-- A table belonging to another application in the same project (the site
-- shares its database). Our migrations must leave it exactly as it is.
create table public.other_app_orders (id integer primary key, note text);
insert into public.other_app_orders values (1, 'untouched');
grant select, insert on public.other_app_orders to anon, authenticated;
