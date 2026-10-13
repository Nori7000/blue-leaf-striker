-- BLUE LEAF STRIKER ランキング用テーブル
-- Supabase の「SQL Editor」にこのファイルの中身を貼り付けて「Run」を押す。

create table if not exists public.scores (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(name) between 1 and 12),
  score      integer     not null check (score between 1 and 500000),
  created_at timestamptz not null default now(),
  mode       text        not null default 'main' check (mode ~ '^[a-z0-9-]{1,32}$')  -- 'main' = 本編, 'monthly-YYYY-MM' = 今月のステージ
);

create index if not exists scores_rank_idx on public.scores (score desc, created_at);
create index if not exists scores_mode_rank_idx on public.scores (mode, score desc, created_at);

-- 誰でも読める。直接の書き込み・変更・削除は誰にも許可しない（登録は下の関数だけ）。
alter table public.scores enable row level security;
drop policy if exists "scores readable by everyone" on public.scores;
create policy "scores readable by everyone" on public.scores
  for select to anon, authenticated using (true);

-- スコア登録用の関数。名前とスコアを検査してから1件だけ追加する。
create or replace function public.submit_score(p_name text, p_score integer, p_mode text default 'main')
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := left(btrim(regexp_replace(coalesce(p_name, ''), '[[:cntrl:]]', '', 'g')), 12);
  v_mode text := coalesce(nullif(btrim(p_mode), ''), 'main');
  v_id   bigint;
begin
  if v_name = '' then v_name := 'NO NAME'; end if;
  if v_mode !~ '^(main|monthly-[0-9]{4}-[0-9]{2})$' then
    raise exception 'invalid mode' using errcode = '22023';
  end if;
  if p_score is null or p_score < 1 or p_score > 500000 then
    raise exception 'invalid score' using errcode = '22023';
  end if;
  -- 連打・荒らし対策：全体で1分あたり30件まで
  if (select count(*) from public.scores where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'too many submissions' using errcode = '22023';
  end if;
  insert into public.scores (name, score, mode) values (v_name, p_score, v_mode) returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.submit_score(text, integer, text) from public;
grant execute on function public.submit_score(text, integer, text) to anon, authenticated;

-- ===== 機体・アイテムの記録（2026-10-ship-items.sql と同じ内容） =====

alter table public.scores add column if not exists ship  text check (ship  in ('leaf', 'lance'));
alter table public.scores add column if not exists items text check (items in ('auto', 'manual'));

-- 5つの引数を受け取る登録関数（古い3つの引数の関数もそのまま使えるように残す）
create or replace function public.submit_score(p_name text, p_score integer, p_mode text, p_ship text, p_items text)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name  text := left(btrim(regexp_replace(coalesce(p_name, ''), '[[:cntrl:]]', '', 'g')), 12);
  v_mode  text := coalesce(nullif(btrim(p_mode), ''), 'main');
  v_ship  text := coalesce(nullif(btrim(p_ship), ''), 'leaf');
  v_items text := coalesce(nullif(btrim(p_items), ''), 'auto');
  v_id    bigint;
begin
  if v_name = '' then v_name := 'NO NAME'; end if;
  if v_mode !~ '^(main|monthly-[0-9]{4}-[0-9]{2})$' then raise exception 'invalid mode' using errcode = '22023'; end if;
  if v_ship not in ('leaf', 'lance') then raise exception 'invalid ship' using errcode = '22023'; end if;
  if v_items not in ('auto', 'manual') then raise exception 'invalid items' using errcode = '22023'; end if;
  if p_score is null or p_score < 1 or p_score > 500000 then raise exception 'invalid score' using errcode = '22023'; end if;
  -- 連打・荒らし対策：全体で1分あたり30件まで
  if (select count(*) from public.scores where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'too many submissions' using errcode = '22023';
  end if;
  insert into public.scores (name, score, mode, ship, items) values (v_name, p_score, v_mode, v_ship, v_items) returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.submit_score(text, integer, text, text, text) from public;
grant execute on function public.submit_score(text, integer, text, text, text) to anon, authenticated;
