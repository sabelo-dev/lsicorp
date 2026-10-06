-- Row-level security. Visitors read published content with the anon key;
-- staff write according to their role.
--   editor           products, documentation, FAQs and pages
--   release_manager  everything an editor can do, plus releases
--   admin            everything, plus site settings, staff and deletions

alter table lsicorp.staff enable row level security;
alter table lsicorp.site_settings enable row level security;
alter table lsicorp.services enable row level security;
alter table lsicorp.products enable row level security;
alter table lsicorp.enquiries enable row level security;
alter table lsicorp.doc_pages enable row level security;
alter table lsicorp.faqs enable row level security;
alter table lsicorp.pages enable row level security;
alter table lsicorp.releases enable row level security;
alter table lsicorp.audit_log enable row level security;

-- Grants are limited to this schema; nothing outside "lsicorp" is touched.
revoke all on all tables in schema lsicorp from anon, authenticated;
grant usage on schema lsicorp to anon, authenticated, service_role;
grant all on all tables in schema lsicorp to service_role;
grant select on lsicorp.site_settings, lsicorp.services, lsicorp.products, lsicorp.doc_pages, lsicorp.faqs, lsicorp.pages, lsicorp.releases
  to anon, authenticated;
grant select on lsicorp.staff, lsicorp.audit_log, lsicorp.enquiries to authenticated;
grant insert, update, delete on lsicorp.staff, lsicorp.services, lsicorp.products, lsicorp.doc_pages, lsicorp.faqs, lsicorp.pages, lsicorp.releases
  to authenticated;
-- A visitor may send an enquiry, and may set only these columns of it.
grant insert (name, email, organisation, service_slug, message, consent) on lsicorp.enquiries to anon, authenticated;
grant update (status, notes), delete on lsicorp.enquiries to authenticated;
grant update on lsicorp.site_settings to authenticated;
grant execute on function lsicorp.current_staff_role(), lsicorp.is_staff(text[]) to anon, authenticated;

-- Reading
create policy "anyone reads site settings" on lsicorp.site_settings for select using (true);
create policy "anyone reads services" on lsicorp.services for select using (true);
create policy "anyone reads products" on lsicorp.products for select using (true);
create policy "anyone reads pages" on lsicorp.pages for select using (true);
create policy "anyone reads published docs" on lsicorp.doc_pages for select
  using (status = 'published' or (select lsicorp.is_staff()));
create policy "anyone reads visible faqs" on lsicorp.faqs for select
  using (visible or (select lsicorp.is_staff()));
create policy "anyone reads published releases" on lsicorp.releases for select
  using (status in ('available', 'superseded', 'withdrawn') or (select lsicorp.is_staff()));
create policy "staff read staff" on lsicorp.staff for select to authenticated
  using (user_id = (select auth.uid()) or (select lsicorp.is_staff()));
create policy "staff read the audit log" on lsicorp.audit_log for select to authenticated
  using ((select lsicorp.is_staff()));

-- Content: any staff member writes, only an admin deletes.
do $$
declare
  t text;
begin
  foreach t in array array['services', 'products', 'doc_pages', 'faqs', 'pages'] loop
    execute format('create policy "staff insert" on lsicorp.%I for insert to authenticated with check ((select lsicorp.is_staff()))', t);
    execute format('create policy "staff update" on lsicorp.%I for update to authenticated using ((select lsicorp.is_staff())) with check ((select lsicorp.is_staff()))', t);
    execute format('create policy "admins delete" on lsicorp.%I for delete to authenticated using ((select lsicorp.is_staff(array[''admin''])))', t);
  end loop;
end
$$;

-- Releases: release managers and admins. A release that has been published is
-- withdrawn, never deleted, so its record stays auditable.
create policy "release managers insert" on lsicorp.releases for insert to authenticated
  with check ((select lsicorp.is_staff(array['release_manager', 'admin'])));
create policy "release managers update" on lsicorp.releases for update to authenticated
  using ((select lsicorp.is_staff(array['release_manager', 'admin'])))
  with check ((select lsicorp.is_staff(array['release_manager', 'admin'])));
create policy "admins delete drafts" on lsicorp.releases for delete to authenticated
  using (status = 'draft' and (select lsicorp.is_staff(array['admin'])));

-- Enquiries: anyone may send one; only staff may read or handle them.
create policy "anyone sends an enquiry" on lsicorp.enquiries for insert with check (true);
create policy "staff read enquiries" on lsicorp.enquiries for select to authenticated using ((select lsicorp.is_staff()));
create policy "staff handle enquiries" on lsicorp.enquiries for update to authenticated
  using ((select lsicorp.is_staff())) with check ((select lsicorp.is_staff()));
create policy "admins delete enquiries" on lsicorp.enquiries for delete to authenticated
  using ((select lsicorp.is_staff(array['admin'])));

-- Site settings and staff: admins only.
create policy "admins update site settings" on lsicorp.site_settings for update to authenticated
  using ((select lsicorp.is_staff(array['admin']))) with check ((select lsicorp.is_staff(array['admin'])));
create policy "admins insert staff" on lsicorp.staff for insert to authenticated
  with check ((select lsicorp.is_staff(array['admin'])));
create policy "admins update staff" on lsicorp.staff for update to authenticated
  using ((select lsicorp.is_staff(array['admin']))) with check ((select lsicorp.is_staff(array['admin'])));
create policy "admins delete staff" on lsicorp.staff for delete to authenticated
  using ((select lsicorp.is_staff(array['admin'])));
