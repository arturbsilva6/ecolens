-- Correção: "coalesce" é uma construção do SQL, não uma função de
-- pg_catalog. Com o prefixo, as três funções abaixo falhavam ao rodar
-- (cota da IA, regras de edição da Comunidade e denúncias).

CREATE OR REPLACE FUNCTION public.ecolens_consume_ai_quota(
  p_user_id uuid,
  p_anonymous boolean,
  p_ip_hash text DEFAULT NULL
)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_day date := (pg_catalog.timezone('utc', pg_catalog.now()))::date;
  v_user_bucket text;
  v_ip_bucket text;
  v_buckets text[];
  v_limits integer[];
  v_count integer;
  i integer;
BEGIN
  IF p_user_id IS NULL OR p_anonymous IS NULL THEN
    RETURN FALSE;
  END IF;
  IF p_ip_hash IS NOT NULL AND p_ip_hash !~ '^[0-9a-f]{64}$' THEN
    RETURN FALSE;
  END IF;

  v_user_bucket := 'user:' || p_user_id::text;
  v_buckets := ARRAY['global', v_user_bucket];
  v_limits := ARRAY[20, CASE WHEN p_anonymous THEN 2 ELSE 5 END];
  IF p_anonymous THEN
    v_buckets := v_buckets || 'anonymous';
    v_limits := v_limits || 8;
  END IF;
  IF p_ip_hash IS NOT NULL THEN
    v_ip_bucket := 'ip:' || p_ip_hash;
    v_buckets := v_buckets || v_ip_bucket;
    v_limits := v_limits || 6;
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(8642011);

  FOR i IN 1 .. pg_catalog.array_length(v_buckets, 1) LOOP
    SELECT request_count INTO v_count
    FROM private.ecolens_ai_usage
    WHERE day_utc = v_day AND bucket = v_buckets[i];
    IF coalesce(v_count, 0) >= v_limits[i] THEN
      RETURN FALSE;
    END IF;
    v_count := NULL;
  END LOOP;

  FOR i IN 1 .. pg_catalog.array_length(v_buckets, 1) LOOP
    INSERT INTO private.ecolens_ai_usage(day_utc, bucket, request_count)
    VALUES (v_day, v_buckets[i], 1)
    ON CONFLICT (day_utc, bucket) DO UPDATE
      SET request_count = private.ecolens_ai_usage.request_count + 1;
  END LOOP;

  RETURN TRUE;
END;
$function$;

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
     and coalesce(pg_catalog.current_setting('ecolens.moderation', true), '') <> 'on' then
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

create or replace function public.report_sighting(p_sighting uuid, p_reason text, p_details text default '')
 returns boolean
 language plpgsql security definer set search_path = '' as $$
declare
 v_user uuid := (select auth.uid());
 v_owner uuid;
 v_today integer;
 v_reporters integer;
begin
 if v_user is null or coalesce((select auth.jwt()->>'is_anonymous'), 'true') <> 'false' then
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
  values (p_sighting, v_user, p_reason, pg_catalog.left(pg_catalog.btrim(coalesce(p_details, '')), 500))
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
