# SchoolDesk by The Shed of Jaga — Sales Site

Mobile-first landing page to collect leads for **SchoolDesk**, the white-labeled
school-management app built and supported by **The Shed of Jaga**.

> School owners see *your* app — your logo, your name, your colours — while we build,
> host and support it. This site turns curious visitors into WhatsApp demo requests.

## Live site

- GitHub Pages: `https://the-shed-of-jaga.github.io/the-shed-of-jaga-sales-lead/`
- (Enable Pages under repo → Settings → Pages → Deploy from branch → `main` / `/(root)`)

## What it does

- Introduces SchoolDesk as a white-label product for schools
- Shows the full feature set (homework, attendance, exams, report cards, notices,
  surveys, push notifications, multilingual EN/HI/TA)
- Explains the white-label model (your brand, private data, setup & support included)
- Captures **sales leads** through an inquiry form → stored in a dedicated Supabase
  `sales_leads` table
- Tracks visitors with Google Analytics 4 (placeholder ID — see `docs/setup.md`)

## Structure

```
index.html          Full landing page (self-contained HTML/CSS/JS, no build step)
docs/setup.md       One-time setup: Supabase project, table SQL, GA4, WhatsApp, deploy
```

## Setup checklist

1. Create the `sales-leads` Supabase project and `sales_leads` table (SQL in `docs/setup.md`)
2. Paste the project URL + anon key into `index.html` (script block at the bottom)
3. Replace `G-XXXXXXXXXX` (GA4) and `919999999999` (WhatsApp) placeholders
4. Push, enable GitHub Pages, share the URL on WhatsApp

## Brand

**The Shed of Jaga — JAGA: Join • Agri • Grow • Apps.**

> &ldquo;Every shed has a story. Ours is one of people, agriculture, growth and applications.&rdquo;