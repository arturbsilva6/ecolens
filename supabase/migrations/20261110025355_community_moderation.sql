-- Moderação da Comunidade (exigência da Google Play para conteúdo de
-- usuários) e limites contra spam.
--   * edited_at: marca registros alterados depois de publicados;
--   * hidden_at: registro oculto por denúncias (some para os outros, o autor
--     ainda vê o próprio);
--   * community_reports: uma denúncia por pessoa e registro; com 3 pessoas
--     diferentes denunciando, o registro é ocultado automaticamente;
--   * limite de 10 publicações por conta por dia e 20 denúncias por dia.

alter table public.community_sightings
  add column edited_at timestamptz,
  add column hidden_at timestamptz;

-- Leitura: publicados e não ocultos, ou os do próprio autor.
drop policy sightings_read on public.community_sightings;
create policy sightings_read on public.community_sightings for select to anon, authenticated
 using ((status = 'published' and hidden_at is null)
   or (owner_id = (select auth.uid()) and (select auth.jwt()->>'is_anonymous') = 'false'));

drop policy community_photo_read on storage.objects;
create policy community_photo_read on storage.objects for select to anon, authenticated
 using (bucket_id = 'community-photos' and exists (
  select 1 from public.community_sightings s where s.photo_path = name
   and ((s.status = 'published' and s.hidden_at is null)
     or (s.owner_id = (select auth.uid()) and (select auth.jwt()->>'is_anonymous') = 'false'))
 ));

drop index if exists public.community_public_page;
drop index if exists public.community_municipal_page;
create index community_public_page on public.community_sightings (created_at desc, id desc)
 where status = 'published' and hidden_at is null;
create index community_municipal_page on public.community_sightings (municipality_id, created_at desc, id desc)
 where status = 'published' and hidden_at is null;

-- Regras de ciclo de vida, agora com edição marcada e moderação protegida.
create or replace function public.community_sighting_guard() returns trigger
 language plpgsql security invoker set search_path = '' as $$
begin
 if TG_OP = 'UPDATE' then
  if new.id <> old.id or new.owner_id <> old.owner_id or new.photo_path <> old.photo_path
     or new.created_at <> old.created_at then
   raise exception 'Sighting identity is immutable' using errcode = '23514';
  end if;
  if old.status = 'deleting' and new.status <> 'deleting'
     or old.status = 'published' and new.status = 'draft' then
   raise exception 'Invalid publication transition' using errcode = '23514';
  end if;
  -- Só a rotina de denúncias muda hidden_at.
  if new.hidden_at is distinct from old.hidden_at
     and pg_catalog.coalesce(pg_catalog.current_setting('ecolens.moderation', true), '') <> 'on' then
   raise exception 'Moderation fields are read-only' using errcode = '42501';
  end if;
  -- edited_at é calculado aqui, nunca vem do app.
  new.edited_at := old.edited_at;
  if old.status = 'published' and (
       new.species_label is distinct from old.species_label
       or new.identification_origin is distinct from old.identification_origin
       or new.notes is distinct from old.notes
       or new.municipality_id is distinct from old.municipality_id
       or new.observed_on is distinct from old.observed_on) then
   new.edited_at := pg_catalog.now();
  end if;
 end if;
 if TG_OP = 'DELETE' then
  if exists (select 1 from storage.objects where bucket_id = 'community-photos' and name = old.photo_path) then
   raise exception 'Remove image using Storage API before removing row' using errcode = '23514';
  end if;
  return old;
 end if;
 if new.status = 'published' and not exists (
  select 1 from storage.objects where bucket_id = 'community-photos' and name = new.photo_path
 ) then
  raise exception 'Upload image before publication' using errcode = '23514';
 end if;
 return new;
end $$;
revoke all on function public.community_sighting_guard() from public, anon, authenticated;

-- Limite de publicações e campos de moderação limpos na criação.
create function public.community_sighting_insert_guard() returns trigger
 language plpgsql security definer set search_path = '' as $$
declare
 v_today integer;
begin
 new.edited_at := null;
 new.hidden_at := null;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('community:' || new.owner_id::text));
 select pg_catalog.count(*) into v_today
   from public.community_sightings
  where owner_id = new.owner_id
    and created_at >= pg_catalog.date_trunc('day', pg_catalog.now());
 if v_today >= 10 then
  raise exception 'ECOLENS_DAILY_LIMIT' using errcode = 'P0001',
   hint = 'Limite de 10 publicações por dia.';
 end if;
 return new;
end $$;
revoke all on function public.community_sighting_insert_guard() from public, anon, authenticated;
create trigger community_sighting_insert_limit before insert on public.community_sightings
 for each row execute function public.community_sighting_insert_guard();

-- Denúncias: sem acesso direto pela API; só pela função abaixo.
create table public.community_reports (
 sighting_id uuid not null references public.community_sightings(id) on delete cascade,
 reporter_id uuid not null references auth.users(id) on delete cascade,
 reason text not null check (reason in ('offensive','spam','wrong_info','inappropriate_photo','other')),
 details text not null default '' check (length(details) <= 500),
 created_at timestamptz not null default now(),
 primary key (sighting_id, reporter_id)
);
create index community_reports_by_reporter on public.community_reports (reporter_id, created_at desc);
alter table public.community_reports enable row level security;
revoke all on public.community_reports from public, anon, authenticated;

create function public.report_sighting(p_sighting uuid, p_reason text, p_details text default '')
 returns boolean
 language plpgsql security definer set search_path = '' as $$
declare
 v_user uuid := (select auth.uid());
 v_owner uuid;
 v_today integer;
 v_reporters integer;
begin
 if v_user is null or pg_catalog.coalesce((select auth.jwt()->>'is_anonymous'), 'true') <> 'false' then
  raise exception 'ECOLENS_LOGIN_REQUIRED' using errcode = '42501';
 end if;
 select owner_id into v_owner from public.community_sightings
  where id = p_sighting and status = 'published' and hidden_at is null;
 if v_owner is null then
  return false;
 end if;
 if v_owner = v_user then
  raise exception 'ECOLENS_OWN_SIGHTING' using errcode = '42501';
 end if;
 select pg_catalog.count(*) into v_today from public.community_reports
  where reporter_id = v_user and created_at >= pg_catalog.now() - interval '1 day';
 if v_today >= 20 then
  raise exception 'ECOLENS_REPORT_LIMIT' using errcode = 'P0001';
 end if;
 insert into public.community_reports (sighting_id, reporter_id, reason, details)
  values (p_sighting, v_user, p_reason, pg_catalog.left(pg_catalog.btrim(pg_catalog.coalesce(p_details, '')), 500))
  on conflict (sighting_id, reporter_id) do nothing;
 select pg_catalog.count(*) into v_reporters from public.community_reports
  where sighting_id = p_sighting;
 if v_reporters >= 3 then
  perform pg_catalog.set_config('ecolens.moderation', 'on', true);
  update public.community_sightings set hidden_at = pg_catalog.now()
   where id = p_sighting and hidden_at is null;
  perform pg_catalog.set_config('ecolens.moderation', '', true);
 end if;
 return true;
end $$;
revoke all on function public.report_sighting(uuid, text, text) from public, anon;
grant execute on function public.report_sighting(uuid, text, text) to authenticated;
