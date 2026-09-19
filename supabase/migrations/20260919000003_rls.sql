-- RLS: un utente vede solo righe del proprio gruppo.

-- Helper security definer: evita ricorsione delle policy su profiles.
create or replace function public.current_group_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select group_id from public.profiles where id = auth.uid();
$$;

-- Gruppo unico dell'MVP (UUID fisso, vedi seed).
create or replace function public.default_group_id()
returns uuid
language sql
immutable
as $$
  select '00000000-0000-0000-0000-00000000c1a0'::uuid;
$$;

alter table public.groups enable row level security;
alter table public.profiles enable row level security;
alter table public.places enable row level security;
alter table public.plans enable row level security;
alter table public.votes enable row level security;
alter table public.place_activity_stats enable row level security;

-- groups
create policy groups_select on public.groups
  for select to authenticated using (id = public.current_group_id());

-- profiles
create policy profiles_select on public.profiles
  for select to authenticated using (group_id = public.current_group_id());
create policy profiles_insert on public.profiles
  for insert to authenticated
  with check (id = auth.uid() and group_id = public.default_group_id());
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and group_id = public.current_group_id());

-- places: dati geografici pubblici, senza group_id (da rivedere in Fase 3)
create policy places_select on public.places
  for select to authenticated using (true);
create policy places_insert on public.places
  for insert to authenticated with check (true);

-- plans: i piani scaduti sono invisibili
create policy plans_select on public.plans
  for select to authenticated
  using (group_id = public.current_group_id() and expires_at > now());
create policy plans_insert on public.plans
  for insert to authenticated
  with check (creator_id = auth.uid() and group_id = public.current_group_id());
create policy plans_delete on public.plans
  for delete to authenticated
  using (creator_id = auth.uid());

-- votes: solo propri voti, su piani visibili (stesso gruppo, non scaduti)
create policy votes_select on public.votes
  for select to authenticated
  using (exists (select 1 from public.plans p where p.id = plan_id));
create policy votes_insert on public.votes
  for insert to authenticated
  with check (profile_id = auth.uid()
    and exists (select 1 from public.plans p where p.id = plan_id));
create policy votes_update on public.votes
  for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
create policy votes_delete on public.votes
  for delete to authenticated using (profile_id = auth.uid());

-- place_activity_stats
create policy stats_select on public.place_activity_stats
  for select to authenticated using (group_id = public.current_group_id());
create policy stats_insert on public.place_activity_stats
  for insert to authenticated with check (group_id = public.current_group_id());
create policy stats_update on public.place_activity_stats
  for update to authenticated
  using (group_id = public.current_group_id())
  with check (group_id = public.current_group_id());
