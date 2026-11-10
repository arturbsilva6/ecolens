-- Correção: 'anonymous' sem tipo era lido como lista ao ser juntado ao array.
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

  v_buckets := ARRAY['global'::text, 'user:' || p_user_id::text];
  v_limits := ARRAY[20, CASE WHEN p_anonymous THEN 2 ELSE 5 END];
  IF p_anonymous THEN
    v_buckets := pg_catalog.array_append(v_buckets, 'anonymous'::text);
    v_limits := pg_catalog.array_append(v_limits, 8);
  END IF;
  IF p_ip_hash IS NOT NULL THEN
    v_buckets := pg_catalog.array_append(v_buckets, 'ip:' || p_ip_hash);
    v_limits := pg_catalog.array_append(v_limits, 6);
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
