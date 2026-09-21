-- Fase 9: chat unica di gruppo, effimera (i messaggi spariscono a mezzanotte).
--
--   messages            testo e/o immagine; RLS: solo il tuo gruppo, non scaduti
--   message_reactions   emoji per messaggio, una per (messaggio, profilo, emoji)
--   bucket chat-images  immagini {group_id}/{message_id}.jpg (privato)
--   purge_expired_messages()   pulizia fisica, chiamata dalla Edge Function
--                              cleanup-chat-images (vedi docs/chat-setup.md)

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  text text check (text is null or char_length(btrim(text)) between 1 and 1000),
  image_path text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  constraint messages_has_content check (text is not null or image_path is not null),
  -- Il path lo decide l'app con l'id del messaggio: {group_id}/{id}.jpg
  constraint messages_image_path_shape check (
    image_path is null or image_path = group_id::text || '/' || id::text || '.jpg'
  )
);
create index messages_group_created_idx on public.messages (group_id, created_at);
create index messages_sender_idx on public.messages (sender_id);
create index messages_expires_idx on public.messages (expires_at);

create table public.message_reactions (
  message_id uuid not null references public.messages (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 16),
  created_at timestamptz not null default now(),
  primary key (message_id, profile_id, emoji)
);
create index message_reactions_profile_idx on public.message_reactions (profile_id);

-- I messaggi scadono alla prossima mezzanotte (Europe/Rome), come i piani.
-- Trigger e non default: il client non può forzare expires_at.
create or replace function public.set_message_expiry()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.expires_at :=
    date_trunc('day', (now() at time zone 'Europe/Rome') + interval '1 day')
    at time zone 'Europe/Rome';
  return new;
end;
$$;

create trigger messages_set_expiry
  before insert on public.messages
  for each row execute function public.set_message_expiry();

alter table public.messages enable row level security;
alter table public.message_reactions enable row level security;

-- messages: solo il proprio gruppo, i messaggi scaduti sono invisibili.
-- Nessuna policy UPDATE: i messaggi non si modificano.
create policy messages_select on public.messages
  for select to authenticated
  using (group_id = public.current_group_id() and expires_at > now());
create policy messages_insert on public.messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and group_id = public.current_group_id()
  );
create policy messages_delete on public.messages
  for delete to authenticated
  using (sender_id = (select auth.uid()));

-- message_reactions: visibili se lo è il messaggio (stesso gruppo, non scaduto).
create policy message_reactions_select on public.message_reactions
  for select to authenticated
  using (exists (select 1 from public.messages m where m.id = message_id));
create policy message_reactions_insert on public.message_reactions
  for insert to authenticated
  with check (
    profile_id = (select auth.uid())
    and exists (select 1 from public.messages m where m.id = message_id)
  );
create policy message_reactions_delete on public.message_reactions
  for delete to authenticated
  using (profile_id = (select auth.uid()));

-- Pulizia fisica dei messaggi scaduti (le reazioni seguono a cascata).
create or replace function public.purge_expired_messages()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.messages where expires_at <= now();
$$;
revoke all on function public.purge_expired_messages() from public, anon, authenticated;

-- "Cancella il mio profilo": ora toglie anche i messaggi (senza, la FK bloccherebbe
-- la cancellazione). Le immagini le libera il cleanup.
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
  delete from public.messages where sender_id = v_uid;
  delete from public.profiles where id = v_uid;
  delete from auth.users where id = v_uid;
end;
$$;
revoke all on function public.delete_my_profile() from public, anon;
grant execute on function public.delete_my_profile() to authenticated;

-- Realtime su messaggi e reazioni.
do $$
declare
  t text;
begin
  foreach t in array array['messages', 'message_reactions'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Storage: bucket privato, solo JPEG, 5 MB. Primo segmento del path = gruppo.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-images', 'chat-images', false, 5242880, array['image/jpeg'])
on conflict (id) do nothing;

create policy chat_images_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = public.current_group_id()::text
  );
create policy chat_images_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = public.current_group_id()::text
  );
-- Si cancella solo il file di un proprio messaggio: l'app toglie prima il file,
-- poi la riga (dopo, la riga non ci sarebbe più per il controllo).
create policy chat_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'chat-images'
    and (storage.foldername(name))[1] = public.current_group_id()::text
    and exists (
      select 1 from public.messages m
      where m.image_path = name and m.sender_id = (select auth.uid())
    )
  );

-- Cleanup programmato: URL della Edge Function accanto a quello di send-push.
alter table public.push_config add column if not exists cleanup_url text;

-- Chiama cleanup-chat-images (asincrono, errori ignorati). Lo lancia pg_cron.
create or replace function public.run_chat_cleanup()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  cfg record;
begin
  select cleanup_url, secret into cfg from public.push_config;
  if not found or cfg.cleanup_url is null then return; end if;
  perform net.http_post(
    url := cfg.cleanup_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', cfg.secret
    ),
    body := '{}'::jsonb
  );
exception when others then
  null;
end;
$$;
revoke all on function public.run_chat_cleanup() from public, anon, authenticated;

-- Per attivarlo (pg_cron da abilitare dal dashboard). 00:05 a Roma sia con ora
-- legale sia solare; la funzione è idempotente, il secondo giro è innocuo:
-- select cron.schedule('chat-cleanup', '5 22,23 * * *', 'select public.run_chat_cleanup()');
