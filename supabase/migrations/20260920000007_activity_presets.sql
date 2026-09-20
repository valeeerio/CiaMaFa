-- Preset di un'attività, già ordinati:
--   punteggio ↓, uso più recente ↓ (mai usati in fondo), distanza dal centro ↑, nome.
-- Visibili: quelli scelti da noi (curated) o lanciati almeno 2 volte.
-- security invoker: la RLS del gruppo vale come per le tabelle.

create or replace function public.activity_presets(p_activity_id text)
returns table (
  name text,
  address text,
  lat double precision,
  lng double precision,
  external_source text,
  external_id text,
  times_used int,
  yes_votes int,
  score numeric,
  last_used_at timestamptz,
  curated boolean,
  distance_km double precision
)
language sql
stable
security invoker
set search_path = public
as $$
  select p.name, p.address, p.lat, p.lng, p.external_source, p.external_id,
         s.times_used, s.yes_votes, s.score, s.last_used_at, s.curated,
         (2 * 6371 * asin(sqrt(
            power(sin(radians(p.lat - g.center_lat) / 2), 2) +
            cos(radians(g.center_lat)) * cos(radians(p.lat)) *
            power(sin(radians(p.lng - g.center_lng) / 2), 2)
         )))::double precision as distance_km
  from public.place_activity_stats s
  join public.places p on p.id = s.place_id
  join public.groups g on g.id = s.group_id
  where s.activity_id = p_activity_id
    and (s.curated or s.times_used >= 2)
  order by s.score desc, s.last_used_at desc nulls last, distance_km, p.name;
$$;
revoke all on function public.activity_presets(text) from public, anon;
grant execute on function public.activity_presets(text) to authenticated;
