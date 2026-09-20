-- Indice per i suggerimenti: luoghi più usati dal gruppo per un'attività.
create index if not exists place_activity_stats_lookup_idx
  on public.place_activity_stats
  (group_id, activity_id, times_used desc, last_used_at desc nulls last);
