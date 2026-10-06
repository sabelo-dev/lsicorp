-- Removes everything supabase/install.sql created. Deletes all of the site's
-- content, releases, enquiries and audit history. There is no undo.
-- Files uploaded to the "lsicorp-release-files" bucket must be removed from
-- the Storage page of the dashboard first; then delete the bucket there.

begin;
drop policy if exists "lsicorp: release managers add release files" on storage.objects;
drop policy if exists "lsicorp: release managers replace release files" on storage.objects;
drop policy if exists "lsicorp: admins remove release files" on storage.objects;
drop schema if exists lsicorp cascade;
commit;
