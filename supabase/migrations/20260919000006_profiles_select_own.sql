-- Necessaria per INSERT ... RETURNING: current_group_id() non vede la riga
-- appena inserita nella stessa istruzione.
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());
