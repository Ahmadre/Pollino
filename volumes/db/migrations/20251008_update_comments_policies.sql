-- Migration: Update comments policies to allow edit/delete by creator via client_id
-- Date: 2025-10-08

-- 1) Add updated_at column
alter table if exists public.comments
  add column if not exists updated_at timestamptz;

-- 2) Trigger to maintain updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_comments_set_updated_at'
  ) then
    create trigger trg_comments_set_updated_at
    before update on public.comments
    for each row execute function public.set_updated_at();
  end if;
end $$;

-- 3) Keep RLS restrictive for update/delete (already disallowed in previous migration)
-- Create SECURITY DEFINER functions to handle edit/delete with client_id verification

create or replace function public.edit_comment(
  p_comment_id bigint,
  p_client_id text,
  p_content text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _ok int;
begin
  if length(trim(coalesce(p_content, ''))) = 0 or length(p_content) > 1000 then
    raise exception 'Invalid content length';
  end if;

  update public.comments
     set content = p_content
   where id = p_comment_id
     and client_id = p_client_id;

  get diagnostics _ok = row_count;
  if _ok = 0 then
    raise exception 'Not allowed to edit this comment';
  end if;
end;
$$;

create or replace function public.delete_comment(
  p_comment_id bigint,
  p_client_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _ok int;
begin
  delete from public.comments
   where id = p_comment_id
     and client_id = p_client_id;

  get diagnostics _ok = row_count;
  if _ok = 0 then
    raise exception 'Not allowed to delete this comment';
  end if;
end;
$$;

-- 4) Grant execute on functions to anon/authenticated
grant execute on function public.edit_comment(bigint, text, text) to anon, authenticated;
grant execute on function public.delete_comment(bigint, text) to anon, authenticated;
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
