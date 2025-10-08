-- Migration: Add client_id to comments for client-side identification (Hive-stored UUID)
-- Date: 2025-10-08

alter table if exists public.comments
  add column if not exists client_id text;

create index if not exists idx_comments_client_id on public.comments(client_id);

-- Note: RLS is currently append-only for anon; further policies (update/delete, rate limiting)
-- can use this client_id. Keeping it nullable for backfill/compatibility.
