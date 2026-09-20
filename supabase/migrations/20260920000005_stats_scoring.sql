-- Classifica dei preset: punteggio = piani lanciati + 0,5 per ogni adesione.

-- Centro del gruppo (parità a zero → più vicini al centro prima).
alter table public.groups
  add column if not exists center_lat double precision not null default 41.0414,
  add column if not exists center_lng double precision not null default 16.7487;

alter table public.place_activity_stats
  add column if not exists yes_votes int not null default 0,
  -- true = preset scelto da noi (sempre visibile); false = compare dopo 2 lanci.
  add column if not exists curated boolean not null default false;

alter table public.place_activity_stats
  add constraint place_stats_non_negative check (times_used >= 0 and yes_votes >= 0);

-- Punteggio calcolato dal database: i pesi si cambiano con una migrazione.
alter table public.place_activity_stats
  add column if not exists score numeric generated always as (times_used + yes_votes * 0.5) stored;

-- I preset esistenti sono quelli scelti a mano.
update public.place_activity_stats set curated = true;

drop index if exists public.place_activity_stats_lookup_idx;
create index place_activity_stats_rank_idx
  on public.place_activity_stats
  (group_id, activity_id, score desc, last_used_at desc nulls last);
