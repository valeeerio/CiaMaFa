-- Fase 11: group_members come fonte di verità per l'appartenenza al gruppo,
-- al posto di profiles.group_id. Tutte le RLS (piani, voti, chat, storage,
-- preset, stats) passano già da current_group_id(): basta riscrivere quella,
-- nessun'altra policy cambia forma. profiles.group_id resta (deprecato, non
-- droppato) finché non si verifica tutto con get_advisors.

alter table public.profiles add column created_at timestamptz not null default now();
update public.profiles p set created_at = u.created_at from auth.users u where u.id = p.id;

create table public.group_members (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  group_id uuid not null references public.groups (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (profile_id, group_id)
);
create index group_members_group_idx on public.group_members (group_id);

-- Backfill: il primo iscritto (per created_at) di ogni gruppo diventa owner.
insert into public.group_members (profile_id, group_id, role, joined_at)
select id, group_id,
  case when row_number() over (partition by group_id order by created_at, id) = 1
       then 'owner' else 'member' end,
  created_at
from public.profiles;

-- Nuovi iscritti: la riga in group_members si crea da sola via trigger,
-- l'insert in profiles lato app (joinGroup) non cambia.
create or replace function public.sync_group_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.group_members (profile_id, group_id, role, joined_at)
  values (
    new.id, new.group_id,
    case when exists (select 1 from public.group_members where group_id = new.group_id)
         then 'member' else 'owner' end,
    new.created_at
  )
  on conflict (profile_id, group_id) do nothing;
  return new;
end;
$$;
revoke all on function public.sync_group_membership() from public, anon;

create trigger profiles_sync_group_membership
  after insert on public.profiles
  for each row execute function public.sync_group_membership();

alter table public.group_members enable row level security;
create policy group_members_select on public.group_members
  for select to authenticated
  using (profile_id = auth.uid() or group_id = public.current_group_id());

-- Da qui in poi la fonte di verità è group_members, non più profiles.group_id.
create or replace function public.current_group_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select group_id from public.group_members where profile_id = auth.uid() limit 1;
$$;
