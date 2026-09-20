-- Fase 7: profilo.
--   * nickname univoco senza distinzione tra maiuscole e minuscole
--   * delete_my_profile(): cancella il proprio profilo (richiesto da Apple per le
--     app che creano l'account dentro l'app)

create unique index profiles_group_nickname_ci_idx
  on public.profiles (group_id, lower(btrim(nickname)));

-- Cancella: i tuoi piani (i trigger tolgono i punti e avvisano il gruppo se non
-- sono scaduti), poi il profilo (i voti seguono a cascata, con i loro punti) e
-- infine l'utente anonimo.
create or replace function public.delete_my_profile()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Non sei autenticato' using errcode = '42501';
  end if;
  delete from public.plans where creator_id = v_uid;
  delete from public.profiles where id = v_uid;
  delete from auth.users where id = v_uid;
end;
$$;
revoke all on function public.delete_my_profile() from public, anon;
grant execute on function public.delete_my_profile() to authenticated;
