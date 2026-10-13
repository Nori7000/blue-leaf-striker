-- BLUE LEAF STRIKER：ランキングに「機体（LEAF / LANCE）」と「アイテムの使い方（AUTO / MANUAL）」を記録する
-- Supabase の「SQL Editor」にこのファイルの中身を貼り付けて「Run」を1回押すだけ。
-- 実行前のスコアは機体・アイテムの表示なしのまま残ります。何度実行しても安全です。

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
