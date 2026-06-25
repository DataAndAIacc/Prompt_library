-- ============================================================
-- RR Prompt Library — Supabase schema, policies and views
-- Run this once in the Supabase SQL editor (Database > SQL).
-- ============================================================

-- ---------- TABLES ----------

create table if not exists public.prompts (
  id            uuid primary key default gen_random_uuid(),
  section       text not null,                 -- section id, e.g. 'writing' or 'ws-ehm'
  workstreams   text[] not null default '{}',  -- optional linked workstream section ids
  title         text not null,
  use_when      text not null default '',
  system_prompt text not null,
  user_template text not null,
  tags          text[] not null default '{}',
  status        text not null default 'pending'  -- 'pending' | 'approved' | 'rejected'
                 check (status in ('pending','approved','rejected')),
  author        text not null default 'anonymous',
  created_at    timestamptz not null default now()
);

create table if not exists public.ratings (
  id         uuid primary key default gen_random_uuid(),
  prompt_id  uuid not null references public.prompts(id) on delete cascade,
  value      int  not null check (value between 1 and 5),
  created_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id         uuid primary key default gen_random_uuid(),
  prompt_id  uuid not null references public.prompts(id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists idx_ratings_prompt  on public.ratings(prompt_id);
create index if not exists idx_feedback_prompt on public.feedback(prompt_id);
create index if not exists idx_prompts_status  on public.prompts(status);

-- ---------- RATING STATS VIEW ----------
-- Aggregated so the app never has to download every individual vote.
create or replace view public.prompt_rating_stats as
  select prompt_id,
         round(avg(value)::numeric, 2) as avg,
         count(*)                      as cnt
  from public.ratings
  group by prompt_id;

-- ---------- ROW LEVEL SECURITY ----------
-- The anon key shipped in the static page is PUBLIC by design.
-- These policies are what actually protect the data.

alter table public.prompts  enable row level security;
alter table public.ratings  enable row level security;
alter table public.feedback enable row level security;

-- PROMPTS
-- Everyone may read only APPROVED prompts (pending/rejected stay hidden).
drop policy if exists "read approved prompts" on public.prompts;
create policy "read approved prompts"
  on public.prompts for select
  using (status = 'approved');

-- Anyone may submit a prompt, but ONLY as 'pending'. They cannot self-approve.
drop policy if exists "submit pending prompts" on public.prompts;
create policy "submit pending prompts"
  on public.prompts for insert
  with check (status = 'pending');

-- No anon UPDATE or DELETE policies = those operations are denied.
-- Maintainers approve/reject from the Supabase dashboard (which bypasses RLS).

-- RATINGS — anyone can read aggregates and add a 1–5 vote; no edits/deletes.
drop policy if exists "read ratings" on public.ratings;
create policy "read ratings" on public.ratings for select using (true);
drop policy if exists "add rating" on public.ratings;
create policy "add rating" on public.ratings for insert with check (value between 1 and 5);

-- FEEDBACK — anyone can read and add; no edits/deletes.
drop policy if exists "read feedback" on public.feedback;
create policy "read feedback" on public.feedback for select using (true);
drop policy if exists "add feedback" on public.feedback;
create policy "add feedback" on public.feedback for insert with check (char_length(body) between 1 and 2000);

-- Expose the view to the API roles.
grant select on public.prompt_rating_stats to anon, authenticated;
