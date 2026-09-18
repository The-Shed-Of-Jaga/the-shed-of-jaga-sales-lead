# Selling SchoolDesk — Setup Guide

This repo holds the marketing / lead-capture website for **SchoolDesk by The Shed of Jaga**
(white-labeled school-management app).

## What&rsquo;s inside

| File | Purpose |
|------|---------|
| `index.html` | The full landing page (mobile-first, self-contained, no build step) |
| `docs/setup.md` | This guide |

---

## Step 1 — Create the lead-capture Supabase project (once)

The landing page&rsquo;s inquiry form stores leads in a **separate Supabase project**
(deliberately isolated from the school app&rsquo;s database).

1. Go to [supabase.com](https://supabase.com) → **New project**.
2. Name it something like `schooldesk-sales-leads` and choose a region near you.
3. On the **Security** step:
   - **Enable Data API** = ✅ ON (the form posts via REST)
   - **Automatically expose new tables** = ❌ OFF (we control access manually)
   - **Enable automatic RLS** = ✅ ON (defense in depth)
4. Note the **Project URL** (e.g. `https://abcd1234.supabase.co`) and the **anon / publishable key**
   (Settings → API → `Project URL` + `anon public` key).

## Step 2 — Create the `sales_leads` table

Open **SQL Editor** in that project and run:

```sql
-- Leads captured by the SchoolDesk sales landing page.
-- RLS is ON; ONLY anonymous INSERT is allowed from anyone (the website form).
-- Nobody (except the DB owner / staff) can read or modify leads from the web.
CREATE TABLE IF NOT EXISTS public.sales_leads (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    school_name   TEXT NOT NULL,
    person_name   TEXT NOT NULL,
    phone         TEXT NOT NULL,
    email         TEXT,
    role          TEXT,
    student_count INTEGER,
    message       TEXT
);

ALTER TABLE public.sales_leads ENABLE ROW LEVEL SECURITY;

-- Required when "Automatically expose new tables" is disabled in the project settings:
-- grants INSERT (only) to the anon role used by the website form. No SELECT/UPDATE/DELETE.
GRANT INSERT ON public.sales_leads TO anon;

-- The website form inserts; nothing else is allowed over the API.
CREATE POLICY "anyone can insert leads" ON public.sales_leads
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Sanity check: you (the owner) can read leads via the dashboard / SQL editor
-- but anonymous SELECT must be denied (default, because RLS with no SELECT policy).
```

You can view your leads anytime in the **Table Editor** → `sales_leads`.

## Step 3 — Configure the landing page

Edit `index.html` and replace the two placeholders in the script block:

```js
const SUPABASE_URL = 'https://vuktzhuotblwqlorkyhq.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_A7Qj_HAV-Ml4HKeSwY82Dw_L7eCm0Hg';
```

Use:
- `SUPABASE_URL` = your project URL
- `SUPABASE_ANON_KEY` = the **anon public** key (the `sb_publishable_...` one — never the service-role key)

> Your anon key is safe to share in the browser — it only permits the `sales_leads` INSERT
> policy above and nothing else.

## Step 4 — Google Analytics (GA4)

Replace `G-XXXXXXXXXX` (two places in `<head>`) with your GA4 Measurement ID:
[analytics.google.com](https://analytics.google.com) → Admin → Data Streams → Web → your stream's
Measurement ID. No ID yet? Leave the placeholder — the page still works; analytics just won't send.

## Step 5 — Point the WhatsApp number at your real number

Already configured: WhatsApp `wa.me/919094946779` and email `jagadishthangavel@gmail.com` are live in `index.html`. Change them anytime by search-replacing in `index.html`.

## Step 6 — Deploy on GitHub Pages

This repo is **public** and named `the-shed-of-jaga-sales-lead`, so after pushing:

1. GitHub → this repo → **Settings → Pages**.
2. Source: **Deploy from a branch** → branch `main`, folder `/ (root)` → **Save**.
3. Wait a minute — your site is live at:
   `https://the-shed-of-jaga.github.io/the-shed-of-jaga-sales-lead/`

Screenshot the URL on your phone: that&rsquo;s the WhatsApp link you send to schools.