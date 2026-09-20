-- Preset iniziali per l'attività "Bar" (Bitetto e dintorni).
-- Ripetibile: non duplica luoghi né statistiche già presenti.
-- Coordinate da OpenStreetMap (via Photon/Nominatim), controllate a mano.
--   external_source 'osm'  → external_id = "<tipo>/<id>" dell'oggetto OSM.

insert into public.places (external_source, external_id, name, address, lat, lng)
values
  ('osm', 'way/617836795',   'Pineta Comunale', 'Bitetto',                                     41.03797, 16.73744),
  ('osm', 'node/6056142322', 'Arco del Tempo',  'Via Saverio Burdi, Bitetto',                  41.03954, 16.74883),
  ('osm', 'node/9514501874', 'GATTI Area',      'Strada Provinciale per Bitetto 29, Bitetto',  41.02676, 16.76480)
on conflict (external_source, external_id) do nothing;

insert into public.place_activity_stats (place_id, activity_id, group_id)
select p.id, 'bar', public.default_group_id()
from public.places p
where p.external_source = 'osm'
  and p.external_id in ('way/617836795', 'node/6056142322', 'node/9514501874')
on conflict (place_id, activity_id, group_id) do nothing;
