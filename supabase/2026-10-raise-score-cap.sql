-- 全5ステージ化に合わせて、ランキングに登録できるスコアの上限を 200,000 → 500,000 に引き上げる。
-- Supabase の「SQL Editor」にこのファイルの中身を貼り付けて「Run」を押す（1回だけ）。

alter table public.scores drop constraint if exists scores_score_check;
alter table public.scores add constraint scores_score_check check (score between 1 and 500000);

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
  if p_score is null or p_score < 1 or p_score > 500000 then
    raise exception 'invalid score' using errcode = '22023';
  end if;
  if (select count(*) from public.scores where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'too many submissions' using errcode = '22023';
  end if;
  insert into public.scores (name, score) values (v_name, p_score) returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.submit_score(text, integer) from public;
grant execute on function public.submit_score(text, integer) to anon, authenticated;
