# AGENTS.md — Campus Outlook Sales Site (The Shed of Jaga)

Session context for working on this repo: `the-shed-of-jaga-sales-lead`.

## What THIS repo is (and is NOT)

- This is the **white-label sales website** for **Campus Outlook** — a school-management
  app built/supported by **The Shed of Jaga**. It captures demo requests (leads).
- It is a **completely separate repo/project from the Bolster Juniors app**
  (`jagadishcts/bolsterjuniors` → the Flutter app; `bolsterjuniors_pages` → its privacy/deletion
  pages). Data and infra are separate. Do not mix them.
- Entity/brand = **The Shed of Jaga**. Never mention, link, or reference **Bolster Juniors**
  on anything served from this site.

## Live site & infra (production)

| Piece | Value | Where it lives |
|---|---|---|
| Live site | `https://the-shed-of-jaga.github.io/the-shed-of-jaga-sales-lead/` | GitHub Pages (Deploy from branch → `main` / `/(root)`) |
| Repo | `https://github.com/The-Shed-Of-Jaga/the-shed-of-jaga-sales-lead` | GitHub org **The-Shed-Of-Jaga** |
| Supabase project | `https://vuktzhuotblwqlorkyhq.supabase.co` | Supabase dashboard (project `vuktzhuotblwqlorkyhq`, FREE plan) |
| Supabase anon key | `sb_publishable_A7Qj_HAV-Ml4HKeSwY82Dw_L7eCm0Hg` | In `index.html` form JS + `docs/setup.md` (public by design) |
| Lead email notify | Supabase DB trigger → Resend API → `jagadishthangavel@gmail.com` | Secret in Supabase `app_settings.resend_key` (NEVER in repo) |
| GA4 | Measurement ID `G-SRGE3XJZ2W` | gtag snippet in `index.html` `<head>` |
| WhatsApp | `wa.me/919094946779` | `index.html` CTA buttons |
| Contact email | `jagadishthangavel@gmail.com` | `index.html` + Resend recipient |

## How the lead flow works (end-to-end)

1. Visitor fills the "Book a free demo" form (~line 710 in `index.html`).
2. Browser POSTs to `{SUPABASE_URL}/rest/v1/sales_leads` with the anon key.
   RLS = INSERT-only for anon (no SELECT/UPDATE/DELETE) — test via Supabase by design.
3. Row lands in `sales_leads` (Table Editor shows it).
4. DB trigger `trg_notify_lead_email` (SECURITY DEFINER, pg_net async) calls
   `net.http_post` to `https://api.resend.com/emails` → email to `jagadishthangavel@gmail.com`
   with subject "New demo request: {school}".
5. GA4 tracks the visit/referral independently.

### ⚠️ CRITICAL convention: NO secrets in this repo, ever
- `index.html` may hold ONLY the **anon** key (public, INSERT-only). Never the service-role key.
- The **Resend** API key must NEVER be written into any file here. It lives only in the Supabase
  DB (`app_settings` table, key `resend_key`). Update it ONLY via Supabase SQL Editor:
  ```sql
  INSERT INTO public.app_settings (key, value)
  VALUES ('resend_key', 'YOUR_NEW_KEY')
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
  ```
- ⚠️ HISTORY LESSON (Sep 2026): a real Resend key was committed in `docs/email-notifications.sql`,
  GitHub secret scanning auto-revoked it, and history had to be rewritten via
  `git filter-branch` + force-push. Never repeat this.

## Site structure & styling conventions

- Single self-contained `index.html` — no build step, no framework. CSS in `<style>`, JS inline.
- Section order is FIXED: Hero → **Gallery** → Features → White-label → Pricing → Contact form → Footer.
- Header brand: 52px logo image + 34px "Campus Outlook" gradient wordmark
  (`linear-gradient(135deg,#EB116E 0%,#701270 25%,#101457 50%,#477571 72%,#F78109 100%)`
  via `background-clip:text`). Parent company attribution only in footer ("by The Shed of Jaga").
- **App Gallery** (`id="gallery"`): 9 phone screenshots in `appgallery/`, carousel with
  prev/next arrows, dots, captions, 4.5s autoplay, swipe. Images load from relative paths —
  keep them in the repo (never absolute URLs to anywhere else).
- Features grid = 15 feature cards. Palette: indigo `#101457/#1A1E7C/#262B8F`, orange `#F78109/#E07306`,
  teal `#477571`, purple `#701270`, rose `#EB116E`.
- Favicon: `favicon-32x32.png`; logo: `the-shed-of-jaga-logo.png` (repo root, relative paths).

## Keep-alive (anti-pause) — CRITICAL for long life

Supabase **free tier pauses a project after ~7 days of low database activity**. The site
(static HTML on GitHub Pages) never stops, but the lead form + email would go dark if the
project pauses. Two INDEPENDENT pingers prevent the pause:

1. **GitHub Actions** — `.github/workflows/keepalive.yml`, every 2 days (`0 8 */2 * *`),
   POSTs `{}/rest/v1/rpc/keepalive_ping` with the anon key. Expect HTTP 204.
   - ⚠️ GitHub **auto-disables scheduled workflows after 60 days with no repo commits**.
     If the repo goes quiet >60 days, this pinger stops silently. Refresh/commit occasionally
     (or rely on pinger #2).
2. **cron-job.org** — free external cron job, same URL/method/headers, every 2 days.
   Independent of GitHub and of the PC. This is the safety net.

The RPC itself: `public.keepalive_ping()` (SQL function, returns void, `SELECT 1` inside =
real DB query → counts as activity; writes nothing, emails nobody). SQL lives in
`docs/keepalive.sql`. anon/authenticated have EXECUTE.

### Monthly 5-minute health check (recommended habit)
- [ ] Site loads: `https://the-shed-of-jaga.github.io/the-shed-of-jaga-sales-lead/` → 200
- [ ] cron-job.org job history shows HTTP 204 (no failures)
- [ ] GitHub Actions → latest keepalive run is green (if repo has recent commits)
- [ ] GitHub Pages settings unchanged (repo public + Pages on `main`/root)
- [ ] Optional: submit a test lead → confirm row appears + email arrives

## Common editing tasks

- **Change features/pricing/copy:** edit the relevant `<section>` in `index.html`. Text is
  plain HTML; keep the section order and class names used by the CSS.
- **Swap gallery screenshots:** replace files in `appgallery/` (same filenames) and commit.
- **Change WhatsApp number/email:** search-replace `919094946779` / `jagadishthangavel@gmail.com`
  in `index.html` (and the Resend recipient in the DB if emails should go elsewhere).
- **Change GA4 ID:** search-replace `G-SRGE3XJZ2W` (two places in `<head>`) in `index.html`.
- **Rotate Resend key:** Supabase SQL Editor only (see the SQL above). Never put it in a file here.
- **Add a table column to `sales_leads`:** alter the table in Supabase + update the INSERT
  statement in `index.html` form JS to match.

## Docs in this repo

- `docs/setup.md` — one-time setup reproduction guide (Supabase project, table+RLS SQL, GA4, WhatsApp, deploy).
- `docs/email-notifications.sql` — the pg_net/Resend trigger SQL for reference (placeholder key only).
- `docs/keepalive.sql` — the anti-pause RPC + how to call it.

## Publishing (every change ships this way)

```bash
git add -A
git commit -m "<concise change summary>"
git push origin main
```
GitHub Pages auto-rebuilds from `main` within ~1 minute — no manual deploy step.

## Rules of thumb
- NEVER commit a real Resend key, Supabase service-role key, or any password/token.
- The only key allowed in the repo is the **anon** key (public, INSERT-only).
- Never write "Bolster Juniors" anywhere in this site's content.
- Keep all asset references relative (`appgallery/...`, `favicon-32x32.png`) so Pages serves them.
- After structural changes to `index.html`, verify: page 200, gallery images 200, favicon 200,
  lead POST → 201, and (if touched) the keep-alive RPC → 204.