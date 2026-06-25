# Rolls-Royce AI Prompt Library

A shared, live library of system prompts and fill-in templates for the account.
Hosted as a static site on **GitHub Pages**, with shared **prompts, ratings and
feedback** stored in a **Supabase** (hosted Postgres) database. Anyone can browse
and contribute; new prompts go live after a maintainer approves them.

> **Data rule:** prompts use placeholders only. Never store client, personal or
> commercially sensitive data. The approval step exists to catch this before
> anything goes live.

---

## How it fits together

- `index.html` — the whole app (UI + data layer). Reads approved prompts from
  Supabase, lets people submit new prompts (as *pending*), and rate / give
  feedback (saved for everyone).
- `schema.sql` — database tables, the rating-stats view, and the row-level
  security (RLS) policies that protect the data.
- `seed.sql` — loads the starter library (52 prompts) as *approved*.
- Runs read-only in "demo mode" if the database isn't configured, so the page
  never breaks.

The Supabase **anon key** is shipped in the page on purpose — that is how
static sites talk to Supabase. It is **not** a secret. Security comes from the
RLS policies in `schema.sql`, which only allow: reading approved prompts,
inserting *pending* prompts, and adding ratings/feedback. No edits or deletes
are possible with the anon key; maintainers approve from the Supabase dashboard.

---

## One-time setup

### 1. Create the database (Supabase)
1. Create a free project at supabase.com.
2. Open **SQL Editor**, paste **`schema.sql`**, run it.
3. Paste **`seed.sql`**, run it (loads the starter prompts).

### 2. Connect the page
1. In Supabase go to **Project Settings → API** and copy:
   - **Project URL**
   - **anon public** key
2. In `index.html`, edit the CONFIG block near the top of the `<script>`:
   ```js
   const SUPABASE_URL  = "https://YOUR-PROJECT.supabase.co";
   const SUPABASE_ANON = "your-anon-public-key";
   ```

### 3. Publish on GitHub Pages
1. Create a repo, add these files, commit and push.
2. **Settings → Pages → Build and deployment → Deploy from a branch**,
   pick your branch and `/ (root)`, save.
3. Your site goes live at `https://<org-or-user>.github.io/<repo>/`.

---

## Using it day to day

- **Browse / search / filter** — by section, workstream or tag.
- **Copy** — grab the system prompt and the user template, fill the
  `{PLACEHOLDERS}`, paste into an approved tool.
- **Rate** — click the stars; the average updates for everyone.
- **Feedback** — leave a note on any prompt; visible to everyone.
- **Add a prompt** — use **＋ Add prompt**. It's submitted as *pending* and
  appears once approved.

## Approving submissions (maintainers)

New prompts arrive with `status = 'pending'`. To review:
1. Supabase → **Table editor → prompts**, filter `status = pending`.
2. Check it contains **no client / personal / sensitive data** and is sound.
3. Set `status` to `approved` (or `rejected`). Approved prompts appear on the
   site on next load.

You can also do it in SQL:
```sql
update public.prompts set status='approved' where id='...';
```

---

## Before you go live (corporate checklist)

This stores account-contributed content in a third-party cloud service, so
**get sign-off from your security / data functions first**. Confirm:

- [ ] Approved to host this content on GitHub Pages + Supabase.
- [ ] Repo visibility is appropriate (public vs org/enterprise) for your account.
- [ ] RLS policies from `schema.sql` are applied (read = approved only; no anon
      update/delete).
- [ ] A named maintainer owns approvals, so unsanitised prompts can't go live.
- [ ] The "placeholders only, no client data" rule is communicated to contributors.

## Limitations

- Ratings are one-vote-per-click (not one-per-person) — fine for a team signal,
  not a strict poll. Add auth if you need per-user voting.
- No login: anyone who can reach the page can read and contribute within the
  RLS rules. Put it behind your org's access controls if that matters.
