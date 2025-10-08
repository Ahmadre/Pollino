-- Migration: Update comments with client_id, name validation, and rate limiting
-- Date: 2025-10-08

-- 1) Add client_id to identify device/client for rate-limiting and UI badges
alter table public.comments
  add column if not exists client_id uuid;

-- 2) Indexes to support rate limiting queries
create index if not exists idx_comments_client_id_created_at on public.comments(client_id, created_at desc);

-- 3) Add name validation constraint (only when provided)
do $$ begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'comments_user_name_length'
  ) then
    alter table public.comments
      add constraint comments_user_name_length
      check (
        user_name is null or length(trim(user_name)) between 2 and 40
      );
  end if;
end $$;

-- 4) Replace insert policy to include rate limiting (max 5 per 5 minutes per client_id)
do $$ begin
  if exists (
    select 1 from pg_policies where schemaname='public' and tablename='comments' and policyname='Allow insert comments'
  ) then
    drop policy "Allow insert comments" on public.comments;
  end if;

  create policy "Allow insert comments" on public.comments
    for insert
    with check (
      -- poll must exist and be active
      exists (select 1 from public.polls p where p.id = poll_id and p.is_active = true)
      -- content validation
      and length(trim(content)) > 0 and length(content) <= 1000
      -- name validation (only when provided)
      and (user_name is null or length(trim(user_name)) between 2 and 40)
      -- rate limiting: require client_id and limit to < 5 comments in last 5 minutes
      and client_id is not null
      and (
        select count(*) from public.comments c
        where c.client_id = public.comments.client_id
          and c.created_at > now() - interval '5 minutes'
      ) < 5
    );
end $$;
