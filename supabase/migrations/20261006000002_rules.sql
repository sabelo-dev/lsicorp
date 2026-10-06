-- Publishing rules, enforced in the database so that no client can skip them.

create function lsicorp.current_staff_role() returns text
language sql stable security definer set search_path = '' as $$
  select role from lsicorp.staff where user_id = (select auth.uid()) and active
$$;

create function lsicorp.is_staff(roles text[] default array['editor', 'release_manager', 'admin']) returns boolean
language sql stable set search_path = '' as $$
  select coalesce(lsicorp.current_staff_role() = any (roles), false)
$$;

-- Returns what is wrong with a link that leaves the LSI website, or null if it may be published.
create function lsicorp.url_problem(url text, allowed text[]) returns text
language plpgsql immutable set search_path = '' as $$
declare
  host text;
begin
  host := lower(substring(url from '^https://([^/?#@:\s]+)(?::[0-9]+)?(?:[/?#]|$)'));
  if host is null then
    return 'must be an https URL without embedded credentials';
  end if;
  if not (host = any (allowed)) then
    return format('host "%s" is not in the allowed external domains', host);
  end if;
  if url ~* '[?&][^=&#]*(token|secret|signature|key|password|credential|x-amz|x-goog|expires)[^=&#]*=' or url ~* '[?&]sig=' then
    return 'looks like a signed or credentialed private URL';
  end if;
  return null;
end
$$;

create function lsicorp.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end
$$;

create function lsicorp.products_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  allowed text[];
  link text;
  problem text;
begin
  select allowed_external_domains into allowed from lsicorp.site_settings;
  foreach link in array array[new.support_url, new.privacy_url] loop
    -- A product link is a path on this site or an allowlisted https URL.
    if link is not null and link !~ '^/([^/]|$)' then
      problem := lsicorp.url_problem(link, coalesce(allowed, '{}'));
      if problem is not null then
        raise exception 'Product link %', problem using errcode = 'check_violation';
      end if;
    end if;
  end loop;

  if exists (select 1 from unnest(new.services) s where not exists (select 1 from lsicorp.services where slug = s)) then
    raise exception 'A product can only list services that exist' using errcode = 'check_violation';
  end if;

  if new.status not in ('available', 'maintenance') and exists (
    select 1 from lsicorp.releases r where r.product_slug = new.slug and r.status = 'available'
  ) then
    raise exception 'This product has a published release. Withdraw it before changing the status to "%".', new.status
      using errcode = 'check_violation';
  end if;
  return new;
end
$$;

create function lsicorp.releases_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  actor uuid := (select auth.uid());
  allowed text[];
  problem text;
  product_status text;
  content_changed boolean;
  workflow constant text[] := array['status', 'prepared_by', 'reviewed_by', 'reviewed_at', 'superseded_by', 'withdrawn_reason', 'updated_at'];
begin
  -- 1. Rules about the record itself. These apply to everyone, including seeds.
  select allowed_external_domains into allowed from lsicorp.site_settings;
  problem := lsicorp.url_problem(new.destination_url, coalesce(allowed, '{}'));
  if problem is not null then
    raise exception 'Destination %', problem using errcode = 'check_violation';
  end if;

  if (new.destination_type = 'web-app') <> (new.platform = 'web') then
    raise exception 'The "web" platform and the "web-app" destination type must be used together'
      using errcode = 'check_violation';
  end if;
  if new.destination_type = 'store' and new.platform = 'linux' then
    raise exception 'A store destination is not valid for Linux' using errcode = 'check_violation';
  end if;

  if new.destination_type = 'file' then
    if new.artifact_filename is null or new.artifact_file_type is null
       or new.artifact_size_bytes is null or new.artifact_sha256 is null then
      raise exception 'A direct file needs a filename, file type, size and SHA-256 checksum'
        using errcode = 'check_violation';
    end if;
    if right(split_part(split_part(new.destination_url, '?', 1), '#', 1), length(new.artifact_filename) + 1)
       <> '/' || new.artifact_filename then
      raise exception 'The destination does not end with the artifact filename "%"', new.artifact_filename
        using errcode = 'check_violation';
    end if;
  elsif num_nonnulls(new.artifact_filename, new.artifact_file_type, new.artifact_size_bytes, new.artifact_sha256) > 0 then
    raise exception 'Artifact details only apply to a direct file download' using errcode = 'check_violation';
  end if;

  if (new.status = 'superseded') <> (new.superseded_by is not null) then
    raise exception 'A superseded release, and only a superseded release, names the version that replaced it'
      using errcode = 'check_violation';
  end if;
  if (new.status = 'withdrawn') <> (new.withdrawn_reason is not null) then
    raise exception 'A withdrawn release, and only a withdrawn release, gives a reason'
      using errcode = 'check_violation';
  end if;
  if new.status = 'superseded' and not exists (
    select 1 from lsicorp.releases r
    where r.product_slug = new.product_slug and r.platform = new.platform
      and r.version = new.superseded_by and r.status in ('available', 'superseded', 'withdrawn')
  ) then
    raise exception 'Version "%" is not a published release for this product and platform', new.superseded_by
      using errcode = 'check_violation';
  end if;

  if new.status = 'available' then
    select status into product_status from lsicorp.products where slug = new.product_slug;
    if product_status not in ('available', 'maintenance') then
      raise exception 'The product status is "%". Set it to "available" before publishing a release.', product_status
        using errcode = 'check_violation';
    end if;
  end if;

  -- 2. Workflow rules for signed-in staff. With no user (the seed file, or
  --    maintenance with the service role) the record is taken as given.
  if actor is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.status <> 'draft' then
      raise exception 'A new release starts as a draft' using errcode = 'check_violation';
    end if;
    new.prepared_by := actor;
    new.reviewed_by := null;
    new.reviewed_at := null;
    return new;
  end if;

  content_changed := (to_jsonb(new) - workflow) is distinct from (to_jsonb(old) - workflow);

  if content_changed then
    if old.status not in ('draft', 'in-review') or new.status not in ('draft', 'in-review') then
      raise exception 'The details of a published release are frozen. Return it to draft to change it, then have it reviewed again.'
        using errcode = 'check_violation';
    end if;
    -- Whoever last changed the details owns them, so cannot also approve them.
    new.prepared_by := actor;
  else
    new.prepared_by := old.prepared_by;
  end if;

  new.reviewed_by := old.reviewed_by;
  new.reviewed_at := old.reviewed_at;

  if new.status is distinct from old.status then
    if (old.status, new.status) not in (
      ('draft', 'in-review'), ('in-review', 'draft'), ('in-review', 'available'),
      ('available', 'superseded'), ('available', 'withdrawn'), ('superseded', 'withdrawn'),
      ('available', 'draft'), ('superseded', 'draft'), ('withdrawn', 'draft')
    ) then
      raise exception 'A release cannot move from "%" to "%"', old.status, new.status
        using errcode = 'check_violation';
    end if;

    if new.status = 'available' then
      if new.prepared_by = actor then
        raise exception 'A release must be approved by a different person from the one who prepared it'
          using errcode = 'check_violation';
      end if;
      new.reviewed_by := actor;
      new.reviewed_at := now();
    elsif new.status in ('draft', 'in-review') then
      new.reviewed_by := null;
      new.reviewed_at := null;
    end if;
  end if;

  return new;
end
$$;

-- Publishing a version supersedes the one it replaces, so there is never a
-- moment with two live downloads or none.
create function lsicorp.releases_supersede_previous() returns trigger
language plpgsql set search_path = '' as $$
begin
  update lsicorp.releases r
  set status = 'superseded', superseded_by = new.version
  where r.product_slug = new.product_slug and r.platform = new.platform and r.channel = new.channel
    and r.status = 'available' and r.id <> new.id;
  return null;
end
$$;

create function lsicorp.audit() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := (select auth.uid());
  row_data jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
begin
  if tg_op = 'UPDATE' and to_jsonb(old) = to_jsonb(new) then
    return null;
  end if;
  insert into lsicorp.audit_log (actor, actor_name, table_name, record_key, action, old_data, new_data)
  values (
    actor,
    (select display_name from lsicorp.staff where user_id = actor),
    tg_table_name,
    case tg_table_name
      when 'releases' then format('%s/%s-%s', row_data ->> 'product_slug', row_data ->> 'platform', row_data ->> 'version')
      when 'doc_pages' then format('%s/%s', row_data ->> 'product_slug', row_data ->> 'slug')
      else coalesce(row_data ->> 'slug', row_data ->> 'user_id', row_data ->> 'id')
    end,
    lower(tg_op),
    case when tg_op <> 'INSERT' then to_jsonb(old) end,
    case when tg_op <> 'DELETE' then to_jsonb(new) end
  );
  return null;
end
$$;

create trigger products_guard before insert or update on lsicorp.products
  for each row execute function lsicorp.products_guard();
create trigger releases_guard before insert or update on lsicorp.releases
  for each row execute function lsicorp.releases_guard();
create trigger releases_supersede_previous after insert or update of status on lsicorp.releases
  for each row when (new.status = 'available') execute function lsicorp.releases_supersede_previous();

do $$
declare
  t text;
begin
  foreach t in array array['site_settings', 'services', 'products', 'doc_pages', 'faqs', 'pages', 'releases'] loop
    execute format('create trigger touch_updated_at before update on lsicorp.%I for each row execute function lsicorp.set_updated_at()', t);
  end loop;
  foreach t in array array['staff', 'site_settings', 'services', 'products', 'doc_pages', 'faqs', 'pages', 'releases'] loop
    execute format('create trigger audit after insert or update or delete on lsicorp.%I for each row execute function lsicorp.audit()', t);
  end loop;
end
$$;
