-- I piani scadono alla prossima mezzanotte (Europe/Rome).
-- Approccio MVP: expires_at calcolato da trigger; la RLS nasconde i piani scaduti
-- (vedi migrazione rls), quindi nessun cron e' necessario per la correttezza.

create or replace function public.set_plan_expiry()
returns trigger
language plpgsql
as $$
begin
  new.expires_at :=
    date_trunc('day', (now() at time zone 'Europe/Rome') + interval '1 day')
    at time zone 'Europe/Rome';
  return new;
end;
$$;

create trigger plans_set_expiry
  before insert on public.plans
  for each row execute function public.set_plan_expiry();

-- Pulizia fisica opzionale (i piani scaduti sono gia' invisibili via RLS).
create or replace function public.purge_expired_plans()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.plans where expires_at <= now();
$$;
revoke all on function public.purge_expired_plans() from public, anon, authenticated;

-- Per attivarla con pg_cron (estensione da abilitare dal dashboard):
-- select cron.schedule('purge-expired-plans', '5 22 * * *', 'select public.purge_expired_plans()');
