-- Aggiornamento automatico dei punti, lato database (atomico e non aggirabile).
--   piano lanciato        → +1 al luogo (e last_used_at)
--   adesione "yes"        → +0,5 (tramite yes_votes) e last_used_at
--   adesione tolta/no     → -0,5
--   piano eliminato PRIMA della scadenza → -1 e -0,5 per ogni sua adesione
--   piano scaduto/pulito a mezzanotte    → nessuna variazione

create or replace function public.apply_place_points(
  p_place_id uuid,
  p_activity_id text,
  p_group_id uuid,
  p_plans int,
  p_yes int,
  p_touch boolean
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_place_id is null then return; end if;
  insert into public.place_activity_stats as s
    (place_id, activity_id, group_id, times_used, yes_votes, last_used_at)
  values (p_place_id, p_activity_id, p_group_id,
          greatest(p_plans, 0), greatest(p_yes, 0),
          case when p_touch then now() end)
  on conflict (place_id, activity_id, group_id) do update set
    times_used   = greatest(s.times_used + p_plans, 0),
    yes_votes    = greatest(s.yes_votes + p_yes, 0),
    last_used_at = case when p_touch then now() else s.last_used_at end;
end;
$$;
revoke all on function public.apply_place_points(uuid, text, uuid, int, int, boolean)
  from public, anon, authenticated;

-- Piano lanciato: +1
create or replace function public.plans_after_insert_points()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.apply_place_points(new.place_id, new.activity_id, new.group_id, 1, 0, true);
  return new;
end;
$$;
create trigger plans_points_insert
  after insert on public.plans
  for each row execute function public.plans_after_insert_points();

-- Piano eliminato prima della scadenza: tolgo il suo punto e quelli delle adesioni.
-- (Gira PRIMA della cancellazione a cascata dei voti, che non tocca più i punti.)
create or replace function public.plans_before_delete_points()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.expires_at > now() then
    perform public.apply_place_points(
      old.place_id, old.activity_id, old.group_id,
      -1,
      -(select count(*)::int from public.votes v where v.plan_id = old.id and v.vote = 'yes'),
      false);
  end if;
  return old;
end;
$$;
create trigger plans_points_delete
  before delete on public.plans
  for each row execute function public.plans_before_delete_points();

-- Adesioni: solo i "yes" contano.
create or replace function public.votes_points()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  pl record;
  delta int := 0;
  touch boolean := false;
begin
  if tg_op = 'INSERT' then
    if new.vote = 'yes' then delta := 1; touch := true; end if;
    select place_id, activity_id, group_id into pl from public.plans where id = new.plan_id;
  elsif tg_op = 'UPDATE' then
    if old.vote = new.vote then return new; end if;
    if new.vote = 'yes' then delta := 1; touch := true; else delta := -1; end if;
    select place_id, activity_id, group_id into pl from public.plans where id = new.plan_id;
  else -- DELETE
    if old.vote <> 'yes' then return old; end if;
    delta := -1;
    -- Se il piano non esiste più (cancellazione a cascata) i punti li gestisce
    -- già il trigger sul piano: qui non si tocca nulla.
    select place_id, activity_id, group_id into pl from public.plans where id = old.plan_id;
    if not found then return old; end if;
  end if;

  if delta <> 0 and pl.place_id is not null then
    perform public.apply_place_points(pl.place_id, pl.activity_id, pl.group_id, 0, delta, touch);
  end if;
  return coalesce(new, old);
end;
$$;
create trigger votes_points_iud
  after insert or update or delete on public.votes
  for each row execute function public.votes_points();

-- Da ora le statistiche le scrivono solo i trigger.
drop policy if exists stats_insert on public.place_activity_stats;
drop policy if exists stats_update on public.place_activity_stats;
