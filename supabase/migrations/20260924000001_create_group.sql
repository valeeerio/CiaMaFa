-- Fase 12: creare un nuovo gruppo (di cui il creatore diventa owner).
-- Serve alla Fase 13 per avere gruppi da trovare oltre a quello esistente:
-- niente switcher (Fase 15) ancora, quindi creare un gruppo NON cambia il
-- gruppo "attivo" di chi lo crea — resta profiles.group_id come oggi.

-- current_group_id() ora deve restare deterministica anche quando un profilo
-- appartiene a più gruppi (dopo questa fase, il creatore ne ha due): finché
-- profiles.group_id esiste, vince quello come gruppo attivo; il fallback a
-- "qualsiasi membership" serve solo per quando sarà rimosso.
create or replace function public.current_group_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select gm.group_id from public.group_members gm
       join public.profiles p on p.id = gm.profile_id
       where gm.profile_id = auth.uid() and gm.group_id = p.group_id),
    (select group_id from public.group_members where profile_id = auth.uid() limit 1)
  );
$$;

-- Vedi anche i gruppi di cui sei membro/owner ma che non sono il tuo gruppo
-- attivo (serve alla Fase 13 per l'area di approvazione delle richieste).
drop policy groups_select on public.groups;
create policy groups_select on public.groups
  for select to authenticated
  using (
    id = public.current_group_id()
    or exists (
      select 1 from public.group_members gm
      where gm.group_id = groups.id and gm.profile_id = auth.uid()
    )
  );

create or replace function public.create_group(p_name text)
returns public.groups
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := btrim(p_name);
  v_group public.groups;
begin
  if v_uid is null then
    raise exception 'Non sei autenticato' using errcode = '42501';
  end if;
  if length(v_name) < 2 or length(v_name) > 40 then
    raise exception 'Nome del gruppo non valido' using errcode = '22023';
  end if;

  insert into public.groups (name) values (v_name) returning * into v_group;
  insert into public.group_members (profile_id, group_id, role)
  values (v_uid, v_group.id, 'owner');

  return v_group;
end;
$$;
revoke all on function public.create_group(text) from public, anon;
grant execute on function public.create_group(text) to authenticated;
