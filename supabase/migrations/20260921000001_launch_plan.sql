-- Fase 4: lancio del piano (RPC) + Realtime sui nuovi piani.
--
-- launch_plan è `security invoker`: RLS e trigger dei punti valgono come per
-- gli insert diretti. Restituisce jsonb con `status`:
--   'launched'           piano creato (plan_id, place_id, place_name, expires_at)
--   'duplicate'          un amico ha già proposto QUESTO posto per QUESTA attività
--                        oggi: niente lancio, si rimanda al suo piano (plan_id)
--   'needs_confirmation' hai già piani attivi oggi (active_count): richiama con
--                        p_confirm_extra = true per lanciare comunque
--
-- Il luogo: stesso (external_source, external_id) se esiste; altrimenti il più
-- vicino entro 30 m (fonde i punti quasi coincidenti); altrimenti ne crea uno.
-- Un luogo nuovo compare tra i preset solo dal 2° lancio (regola dei preset).

create or replace function public.launch_plan(
  p_activity_id text,
  p_name text,
  p_lat double precision,
  p_lng double precision,
  p_address text default null,
  p_external_source text default null,
  p_external_id text default null,
  p_confirm_extra boolean default false
) returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_group uuid := public.current_group_id();
  v_emoji text;
  v_label text;
  v_name text := coalesce(nullif(btrim(p_name), ''), 'Punto sulla mappa');
  v_place uuid;
  v_place_name text;
  v_existing uuid;
  v_active int;
  v_plan uuid;
  v_expires timestamptz;
begin
  if v_uid is null or v_group is null then
    raise exception 'Non sei nel gruppo' using errcode = '42501';
  end if;
  if p_lat is null or p_lng is null
     or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'Coordinate non valide' using errcode = '22023';
  end if;

  select e, l into v_emoji, v_label
  from (values
    ('bar', '🍻', 'Bar'),
    ('bombolone', '🍁', 'Bombolone'),
    ('chill', '🛋️', 'Posto Chill'),
    ('mangiare', '🍽️', 'Mangiare'),
    ('bho', '🎲', 'Bho, vediamoci e decidiamo')
  ) as a(id, e, l)
  where a.id = p_activity_id;
  if v_label is null then
    raise exception 'Attività sconosciuta' using errcode = '22023';
  end if;

  -- 1) stesso luogo esterno; 2) il più vicino entro 30 m
  if p_external_id is not null then
    select id, name into v_place, v_place_name from public.places
    where external_source is not distinct from p_external_source
      and external_id = p_external_id;
  end if;
  if v_place is null then
    select id, name into v_place, v_place_name from public.places
    where 2 * 6371000 * asin(sqrt(
            power(sin(radians(lat - p_lat) / 2), 2) +
            cos(radians(p_lat)) * cos(radians(lat)) *
            power(sin(radians(lng - p_lng) / 2), 2))) <= 30
    order by 2 * 6371000 * asin(sqrt(
            power(sin(radians(lat - p_lat) / 2), 2) +
            cos(radians(p_lat)) * cos(radians(lat)) *
            power(sin(radians(lng - p_lng) / 2), 2)))
    limit 1;
  end if;

  -- Duplicato: stessa attività e stesso luogo già proposti oggi (da chiunque).
  if v_place is not null then
    select id into v_existing from public.plans
    where activity_id = p_activity_id and place_id = v_place
      and expires_at > now()
    order by created_at limit 1;
    if v_existing is not null then
      return jsonb_build_object('status', 'duplicate', 'plan_id', v_existing);
    end if;
  end if;

  -- Ne hai già di attivi oggi? Serve conferma.
  select count(*) into v_active from public.plans
  where creator_id = v_uid and expires_at > now();
  if v_active > 0 and not p_confirm_extra then
    return jsonb_build_object('status', 'needs_confirmation', 'active_count', v_active);
  end if;

  if v_place is null then
    insert into public.places (name, address, lat, lng, external_source, external_id)
    values (v_name, p_address, p_lat, p_lng, p_external_source, p_external_id)
    on conflict (external_source, external_id) do nothing
    returning id into v_place;
    if v_place is null then
      select id into v_place from public.places
      where external_source = p_external_source and external_id = p_external_id;
    end if;
    v_place_name := v_name;
  end if;

  insert into public.plans (group_id, activity_id, emoji, label, place_id, creator_id)
  values (v_group, p_activity_id, v_emoji, v_label, v_place, v_uid)
  returning id, expires_at into v_plan, v_expires;

  return jsonb_build_object(
    'status', 'launched',
    'plan_id', v_plan,
    'place_id', v_place,
    'place_name', v_place_name,
    'expires_at', v_expires
  );
end;
$$;

revoke all on function public.launch_plan(text, text, double precision, double precision, text, text, text, boolean)
  from public, anon;
grant execute on function public.launch_plan(text, text, double precision, double precision, text, text, text, boolean)
  to authenticated;

-- Realtime: gli amici con l'app aperta ricevono i nuovi piani (RLS applicata).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'plans'
  ) then
    alter publication supabase_realtime add table public.plans;
  end if;
end $$;
