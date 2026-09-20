-- ----------------------------------------------------------------------------
-- Supabase Keep-Alive RPC (anti-pause)
-- Free-plan projects pause after ~7 days of LOW DATABASE ACTIVITY.
-- This lightweight function executes a real Postgres query (so it counts as
-- activity), inserts nothing, sends nothing, and costs nothing.
--
-- To run: once, in the Supabase Dashboard > SQL Editor.
-- After this, it is called automatically by .github/workflows/keepalive.yml
-- and/or an external cron (cron-job.org) every 2-3 days.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.keepalive_ping()
RETURNS void
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT 1;
$$;

REVOKE ALL ON FUNCTION public.keepalive_ping() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.keepalive_ping() TO anon;
GRANT EXECUTE ON FUNCTION public.keepalive_ping() TO authenticated;
GRANT EXECUTE ON FUNCTION public.keepalive_ping() TO service_role;

-- Sanity check: expect f (anon can EXECUTE, that's intended for the cron pinger)
SELECT has_function_privilege('anon', 'public.keepalive_ping()', 'EXECUTE') AS anon_exec;

-- Manual smoke test (should return 204/200, empty body):
--   curl -s -o /dev/null -w "%{http_code}\n" -X POST \
--     "https://vuktzhuotblwqlorkyhq.supabase.co/rest/v1/rpc/keepalive_ping" \
--     -H "apikey: sb_publishable_A7Qj_HAV-Ml4HKeSwY82Dw_L7eCm0Hg" \
--     -H "Authorization: Bearer sb_publishable_A7Qj_HAV-Ml4HKeSwY82Dw_L7eCm0Hg" \
--     -H "Content-Type: application/json" -d "{}"