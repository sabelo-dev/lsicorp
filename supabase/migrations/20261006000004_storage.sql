-- Bucket for direct-download release files. Files are publicly readable by
-- URL; only release managers and admins can add or replace them.
-- To serve files from this bucket, add the project's host
-- (<project-ref>.supabase.co) to site_settings.allowed_external_domains.

insert into storage.buckets (id, name, public)
values ('lsicorp-release-files', 'lsicorp-release-files', true)
on conflict (id) do nothing;

create policy "lsicorp: release managers add release files" on storage.objects for insert to authenticated
  with check (bucket_id = 'lsicorp-release-files' and (select lsicorp.is_staff(array['release_manager', 'admin'])));
create policy "lsicorp: release managers replace release files" on storage.objects for update to authenticated
  using (bucket_id = 'lsicorp-release-files' and (select lsicorp.is_staff(array['release_manager', 'admin'])))
  with check (bucket_id = 'lsicorp-release-files' and (select lsicorp.is_staff(array['release_manager', 'admin'])));
create policy "lsicorp: admins remove release files" on storage.objects for delete to authenticated
  using (bucket_id = 'lsicorp-release-files' and (select lsicorp.is_staff(array['admin'])));
