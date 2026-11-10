-- Cota da IA com visitantes separados.
-- Antes, poucas sessões anônimas esgotavam a cota global do dia para todos.
-- Agora, por dia (UTC):
--   * total: 20 análises;
--   * contas: 5 análises cada;
--   * visitantes (sessão anônima): 2 cada e 8 somadas, para que as contas
--     sempre tenham pelo menos 12 análises disponíveis;
--   * por rede (hash do IP, sem guardar o IP): 6, contas e visitantes juntos.
DROP FUNCTION IF EXISTS public.ecolens_consume_ai_quota(uuid);

CREATE FUNCTION public.ecolens_consume_ai_quota(
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
    IF pg_catalog.coalesce(v_count, 0) >= v_limits[i] THEN
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

REVOKE ALL ON FUNCTION public.ecolens_consume_ai_quota(uuid, boolean, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ecolens_consume_ai_quota(uuid, boolean, text)
  TO service_role;

-- Contagens antigas não precisam ficar para sempre.
DELETE FROM private.ecolens_ai_usage
WHERE day_utc < (pg_catalog.timezone('utc', pg_catalog.now()))::date - 7;
