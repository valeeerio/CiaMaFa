-- Altri preset per "Bar": locali non presenti in OpenStreetMap.
-- Coordinate fornite dal gruppo (Apple Maps), verificate con il reverse geocoding.
--   external_source 'seed' → external_id = slug scelto da noi.
-- Ripetibile: non duplica luoghi né statistiche già presenti.

insert into public.places (external_source, external_id, name, address, lat, lng)
values
  ('seed', 'frida-amare',             'Frida a''mare', 'Lungomare Cristoforo Colombo, Santo Spirito, Bari', 41.16871, 16.74029),
  ('seed', 'momento-bar-sannicandro', 'Momento Bar',   'Sannicandro di Bari',                                 40.99224, 16.80070)
on conflict (external_source, external_id) do nothing;

insert into public.place_activity_stats (place_id, activity_id, group_id)
select p.id, 'bar', public.default_group_id()
from public.places p
where p.external_source = 'seed'
  and p.external_id in ('frida-amare', 'momento-bar-sannicandro')
on conflict (place_id, activity_id, group_id) do nothing;
