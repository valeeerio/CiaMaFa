-- Fase 8: push notification (FCM).
--
--   device_tokens   token FCM di ogni telefono, legato a un profilo
--   register_device_token / unregister_device_token   (RPC, solo il proprio)
--   push_config     URL + segreto dell'Edge Function send-push (nessun accesso
--                   dall'app: RLS attiva e nessuna policy)
--   trigger         nuovo piano / voto / annullamento → send-push via pg_net
--
-- L'invio non blocca mai l'operazione: pg_net è asincrono e ogni errore del
-- trigger viene ignorato.

create extension if not exists pg_net with schema extensions;

create table public.device_tokens (
  token text primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);
create index device_tokens_profile_idx on public.device_tokens (profile_id);

alter table public.device_tokens enable row level security;
-- Ognuno vede ed elimina solo i propri; si scrive solo via RPC.
create policy device_tokens_select_own on public.device_tokens
  for select to authenticated using (profile_id = auth.uid());
create policy device_tokens_delete_own on public.device_tokens
  for delete to authenticated using (profile_id = auth.uid());

-- Se lo stesso telefono cambia profilo, il token passa al nuovo.
create or replace function public.register_device_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Non sei autenticato' using errcode = '42501';
  end if;
  if p_token is null or btrim(p_token) = '' or p_platform not in ('ios', 'android') then
    raise exception 'Token o piattaforma non validi' using errcode = '22023';
  end if;
  insert into public.device_tokens (token, profile_id, platform)
  values (p_token, auth.uid(), p_platform)
  on conflict (token) do update
    set profile_id = excluded.profile_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;
revoke all on function public.register_device_token(text, text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;

create or replace function public.unregister_device_token(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.device_tokens where token = p_token and profile_id = auth.uid();
$$;
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.unregister_device_token(text) to authenticated;

-- Configurazione dell'invio: una sola riga (URL della funzione + segreto).
create table public.push_config (
  id boolean primary key default true check (id),
  function_url text not null,
  secret text not null
);
alter table public.push_config enable row level security;

-- Chiama send-push (asincrono). Errori ignorati: la push è un di più.
create or replace function public.notify_push(p_payload jsonb)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  cfg record;
begin
  select function_url, secret into cfg from public.push_config;
  if not found then return; end if;
  perform net.http_post(
    url := cfg.function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', cfg.secret
    ),
    body := p_payload
  );
exception when others then
  null;
end;
$$;
revoke execute on function public.notify_push(jsonb) from public, anon, authenticated;

create or replace function public.plans_after_insert_push()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.notify_push(jsonb_build_object('kind', 'plan', 'plan_id', new.id));
  return new;
end;
$$;
revoke execute on function public.plans_after_insert_push() from public, anon, authenticated;
create trigger plans_push_insert
  after insert on public.plans
  for each row execute function public.plans_after_insert_push();

-- Voti: solo nuovi o cambiati, e non quello automatico del creatore (lo scarta
-- la funzione: il votante coincide con il creatore).
create or replace function public.votes_after_write_push()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and old.vote = new.vote then
    return new;
  end if;
  perform public.notify_push(jsonb_build_object(
    'kind', 'vote', 'plan_id', new.plan_id, 'voter_id', new.profile_id
  ));
  return new;
end;
$$;
revoke execute on function public.votes_after_write_push() from public, anon, authenticated;
create trigger votes_push_write
  after insert or update on public.votes
  for each row execute function public.votes_after_write_push();

create or replace function public.cancellations_after_insert_push()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.notify_push(jsonb_build_object(
    'kind', 'cancel', 'cancellation_id', new.id
  ));
  return new;
end;
$$;
revoke execute on function public.cancellations_after_insert_push() from public, anon, authenticated;
create trigger cancellations_push_insert
  after insert on public.plan_cancellations
  for each row execute function public.cancellations_after_insert_push();
