-- -----------------------------------------------------------------------------
-- Email notification for new sales_leads rows (Campus Outlook landing page).
-- Sends an email to jagadishthangavel@gmail.com every time the lead form saves.
--
-- Prerequisites (ONCE):
--   1. Create a free Resend account at https://resend.com
--      Sign up with jagadishthangavel@gmail.com (the recipient address) so the
--      no-domain test sender `onboarding@resend.dev` is allowed to email you.
--   2. Copy your API key (Resend -> API Keys -> "re_...").
--   3. Run this whole file in the project's SQL Editor
--      (project vuktzhuotblwqlorkyhq), replacing REPLACE_WITH_YOUR_RESEND_KEY.
--
-- NOTE: your key is stored in a private app_settings table (RLS, zero policies)
-- because Supabase's SQL Editor cannot ALTER DATABASE custom app.settings.*
-- params (permission denied 42501). The trigger reads it as postgres via
-- SECURITY DEFINER, which bypasses RLS, so anon/authenticated can never read it.
-- Everything below is idempotent (IF NOT EXISTS / CREATE OR REPLACE).
-- -----------------------------------------------------------------------------

-- 1) Enable pg_net (async HTTP from the DB, same as the main app uses).
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2) Private key store: RLS ON, ZERO policies -> deny-by-default over the API.
CREATE TABLE IF NOT EXISTS public.app_settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.app_settings FROM anon, authenticated, PUBLIC;
GRANT  ALL ON public.app_settings TO service_role;

-- 3) Store your Resend key (swap in the real key before running).
INSERT INTO public.app_settings (key, value)
VALUES ('resend_key', 'REPLACE_WITH_YOUR_RESEND_KEY')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 4) Trigger function: reads the key, builds the email, POSTs to Resend async.
CREATE OR REPLACE FUNCTION public.notify_lead_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  api_key text;
  payload jsonb;
BEGIN
  SELECT value INTO api_key
    FROM public.app_settings
   WHERE key = 'resend_key';

  IF api_key IS NULL OR api_key = '' OR api_key LIKE '%REPLACE%' THEN
    RAISE NOTICE 'resend_key not set; lead email skipped';
    RETURN NEW;
  END IF;

  payload := jsonb_build_object(
    'from',    'Campus Outlook <onboarding@resend.dev>',
    'to',      jsonb_build_array('jagadishthangavel@gmail.com'),
    'subject', format('New demo request: %s', NEW.school_name),
    'html', format(
      '<b>New Campus Outlook demo request</b><br><br>'
      'School: <b>%s</b><br>'
      'Contact: %s<br>'
      'Phone: %s<br>'
      'Email: %s<br>'
      'Role: %s<br>'
      'Students: %s<br>'
      'Message: %s<br><br>'
      'Received: %s',
      NEW.school_name,
      NEW.person_name,
      NEW.phone,
      COALESCE(NEW.email, '—'),
      COALESCE(NEW.role, '—'),
      COALESCE(NEW.student_count::text, '—'),
      COALESCE(NEW.message, '—'),
      to_char(NEW.created_at AT TIME ZONE 'Asia/Kolkata', 'DD Mon YYYY, HH24:MI')
    )
  );

  -- Async POST - the insert never waits on the email.
  PERFORM net.http_post(
    url     := 'https://api.resend.com/emails',
    body    := payload,
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || api_key,
      'Content-Type',  'application/json'
    )
  );
  RETURN NEW;
END;
$$;

-- 5) Fire the email on every new lead.
DROP TRIGGER IF EXISTS trg_notify_lead_email ON public.sales_leads;
CREATE TRIGGER trg_notify_lead_email
  AFTER INSERT ON public.sales_leads
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_lead_email();