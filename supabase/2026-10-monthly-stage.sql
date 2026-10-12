-- 「今月のステージ」用に、スコアがどのモードの記録かを残す列を追加する。
-- Supabase の「SQL Editor」にこのファイルの中身を貼り付けて「Run」を押す（1回だけ）。
-- 既存の記録はすべて本編（main）として扱われる。

alter table public.scores add column if not exists mode text not null default 'main';
alter table public.scores drop constraint if exists scores_mode_check;
alter table public.scores add constraint scores_mode_check check (mode ~ '^[a-z0-9-]{1,32}$');
create index if not exists scores_mode_rank_idx on public.scores (mode, score desc, created_at);

drop function if exists public.submit_score(text, integer);
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
  if (select count(*) from public.scores where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'too many submissions' using errcode = '22023';
  end if;
  insert into public.scores (name, score, mode) values (v_name, p_score, v_mode) returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.submit_score(text, integer, text) from public;
grant execute on function public.submit_score(text, integer, text) to anon, authenticated;
