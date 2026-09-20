-- Fase 6: eliminazione del piano + avviso al gruppo.
--
-- Chi elimina un piano PRIMA della scadenza lascia una riga in
-- plan_cancellations (scritta solo dal trigger): gli amici con l'app aperta la
-- ricevono via Realtime e vedono il banner "… ha annullato il piano". I piani
-- scaduti/ripuliti a mezzanotte non generano nulla. (L'eliminazione la fa già la
-- policy plans_delete: solo il creatore; i punti li toglie già plans_points_delete.)

create table public.plan_cancellations (
  id uuid primary key default gen_random_uuid(),
  -- Niente chiavi esterne: il piano non esiste più e il profilo può sparire.
  plan_id uuid not null,
  group_id uuid not null,
  creator_id uuid not null,
  creator_nickname text not null,
  emoji text not null,
  label text not null,
  place_name text,
  created_at timestamptz not null default now()
);

alter table public.plan_cancellations enable row level security;
-- Sola lettura per il gruppo; nessuna policy di scrittura (solo il trigger).
create policy cancellations_select on public.plan_cancellations
  for select to authenticated using (group_id = public.current_group_id());

create or replace function public.plans_before_delete_notify()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.expires_at > now() then
    insert into public.plan_cancellations
      (plan_id, group_id, creator_id, creator_nickname, emoji, label, place_name)
    select old.id, old.group_id, old.creator_id,
           coalesce((select nickname from public.profiles where id = old.creator_id), '?'),
           old.emoji, old.label,
           (select name from public.places where id = old.place_id);
  end if;
  return old;
end;
$$;
revoke execute on function public.plans_before_delete_notify() from public, anon, authenticated;

create trigger plans_cancel_notify
  before delete on public.plans
  for each row execute function public.plans_before_delete_notify();

-- Le righe servono solo per il banner: la pulizia notturna le toglie.
create or replace function public.purge_expired_plans()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.plans where expires_at <= now();
  delete from public.plan_cancellations where created_at < now() - interval '1 day';
$$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'plan_cancellations'
  ) then
    alter publication supabase_realtime add table public.plan_cancellations;
  end if;
end $$;
