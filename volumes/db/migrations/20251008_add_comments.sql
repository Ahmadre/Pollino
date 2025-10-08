-- Migration: Add comments feature for polls
-- Date: 2025-10-08

-- 1) Table
create table if not exists public.comments (
  id bigint generated always as identity primary key,
  poll_id bigint not null references public.polls(id) on delete cascade,
  user_name text, -- optional display name
  is_anonymous boolean not null default true,
  content text not null,
  created_at timestamptz not null default now()
);

-- 2) Constraints
alter table public.comments
  add constraint comments_content_not_empty check (length(trim(content)) > 0),
  add constraint comments_content_max_length check (length(content) <= 1000);

-- 3) Indexes
create index if not exists idx_comments_poll_id on public.comments(poll_id);
create index if not exists idx_comments_poll_id_created_at on public.comments(poll_id, created_at desc);

-- 4) RLS
alter table public.comments enable row level security;

-- Allow anyone (anon or authenticated) to read comments
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='comments' and policyname='Allow read comments'
  ) then
    create policy "Allow read comments" on public.comments
      for select using (true);
  end if;
end $$;

-- Allow anyone to insert comments, enforce non-empty and reference existing poll
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='comments' and policyname='Allow insert comments'
  ) then
    create policy "Allow insert comments" on public.comments
      for insert
      with check (
        exists (select 1 from public.polls p where p.id = poll_id and p.is_active = true)
        and length(trim(content)) > 0 and length(content) <= 1000
      );
  end if;
end $$;

-- Optional: disallow updates/deletes for anon; keep table append-only except cascade deletions
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='comments' and policyname='Disallow update comments'
  ) then
    create policy "Disallow update comments" on public.comments
      for update using (false);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='comments' and policyname='Disallow delete comments'
  ) then
    create policy "Disallow delete comments" on public.comments
      for delete using (false);
  end if;
end $$;

-- 5) (Optional) View for counts (can be used if needed)
create or replace view public.comments_count_per_poll as
select poll_id, count(*)::bigint as comments_count
from public.comments
group by poll_id;
