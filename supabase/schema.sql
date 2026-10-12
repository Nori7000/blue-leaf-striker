-- BLUE LEAF STRIKER ランキング用テーブル
-- Supabase の「SQL Editor」にこのファイルの中身を貼り付けて「Run」を押す。

create table if not exists public.scores (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(name) between 1 and 12),
  score      integer     not null check (score between 1 and 200000),
  created_at timestamptz not null default now()
);

create index if not exists scores_rank_idx on public.scores (score desc, created_at);

-- 誰でも読める。直接の書き込み・変更・削除は誰にも許可しない（登録は下の関数だけ）。
alter table public.scores enable row level security;
drop policy if exists "scores readable by everyone" on public.scores;
create policy "scores readable by everyone" on public.scores
  for select to anon, authenticated using (true);

-- スコア登録用の関数。名前とスコアを検査してから1件だけ追加する。
create or replace function public.submit_score(p_name text, p_score integer)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := left(btrim(regexp_replace(coalesce(p_name, ''), '[[:cntrl:]]', '', 'g')), 12);
  v_id   bigint;
begin
  if v_name = '' then v_name := 'NO NAME'; end if;
  if p_score is null or p_score < 1 or p_score > 200000 then
    raise exception 'invalid score' using errcode = '22023';
  end if;
  -- 連打・荒らし対策：全体で1分あたり30件まで
  if (select count(*) from public.scores where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'too many submissions' using errcode = '22023';
  end if;
  insert into public.scores (name, score) values (v_name, p_score) returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.submit_score(text, integer) from public;
grant execute on function public.submit_score(text, integer) to anon, authenticated;
