-- "Gatti" area di servizio sulla SP206 (Via Nuova Circonvallazione), Bitetto.
-- Con il "Bar Gatti" accanto. Diverso dal distributore "GATTI Area" sulla SP90
-- già nei preset. Coordinate fornite dal gruppo (Google Maps).
-- Ripetibile: non duplica luoghi né statistiche già presenti.

insert into public.places (external_source, external_id, name, address, lat, lng)
values
  ('seed', 'gatti-sp206', 'Gatti SP206', 'SP206 (Via Nuova Circonvallazione), Bitetto', 41.03342, 16.74480)
on conflict (external_source, external_id) do nothing;

insert into public.place_activity_stats (place_id, activity_id, group_id)
select p.id, 'bar', public.default_group_id()
from public.places p
where p.external_source = 'seed'
  and p.external_id in ('gatti-sp206')
on conflict (place_id, activity_id, group_id) do nothing;
