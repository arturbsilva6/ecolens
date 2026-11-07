-- Migration 20261102052336
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
CREATE TABLE IF NOT EXISTS private.ecolens_ai_usage (
  day_utc date NOT NULL,
  bucket text NOT NULL,
  request_count integer NOT NULL DEFAULT 0 CHECK (request_count >= 0),
  PRIMARY KEY (day_utc, bucket)
);
ALTER TABLE private.ecolens_ai_usage ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.ecolens_ai_usage FROM PUBLIC, anon, authenticated;
CREATE OR REPLACE FUNCTION public.ecolens_consume_ai_quota(p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_day date := (pg_catalog.timezone('utc', pg_catalog.now()))::date;
  v_global integer := 0;
  v_user integer := 0;
  v_bucket text;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  v_bucket := 'user:' || p_user_id::text;
  PERFORM pg_catalog.pg_advisory_xact_lock(8642011);

  SELECT request_count INTO v_global
  FROM private.ecolens_ai_usage
  WHERE day_utc = v_day AND bucket = 'global';

  SELECT request_count INTO v_user
  FROM private.ecolens_ai_usage
  WHERE day_utc = v_day AND bucket = v_bucket;

  IF pg_catalog.coalesce(v_global, 0) >= 20 OR
     pg_catalog.coalesce(v_user, 0) >= 5 THEN
    RETURN FALSE;
  END IF;

  INSERT INTO private.ecolens_ai_usage(day_utc, bucket, request_count)
  VALUES (v_day, 'global', 1)
  ON CONFLICT (day_utc, bucket) DO UPDATE
    SET request_count = private.ecolens_ai_usage.request_count + 1;

  INSERT INTO private.ecolens_ai_usage(day_utc, bucket, request_count)
  VALUES (v_day, v_bucket, 1)
  ON CONFLICT (day_utc, bucket) DO UPDATE
    SET request_count = private.ecolens_ai_usage.request_count + 1;

  RETURN TRUE;
END;
$function$

REVOKE ALL ON FUNCTION public.ecolens_consume_ai_quota(uuid)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ecolens_consume_ai_quota(uuid)
TO service_role;
