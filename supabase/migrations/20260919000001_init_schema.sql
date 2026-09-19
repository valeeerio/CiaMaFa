-- CiaMaFa: schema iniziale

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  group_id uuid not null references public.groups (id),
  nickname text not null,
  notifications_enabled boolean not null default true,
  unique (group_id, nickname)
);

create table public.places (
  id uuid primary key default gen_random_uuid(),
  external_id text,
  external_source text,
  name text not null,
  address text,
  lat double precision not null,
  lng double precision not null,
  created_at timestamptz not null default now(),
  unique (external_source, external_id)
);

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id),
  activity_id text not null,
  emoji text not null,
  label text not null,
  place_id uuid references public.places (id),
  creator_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '1 day')
);

create table public.votes (
  plan_id uuid not null references public.plans (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  vote text not null check (vote in ('yes', 'no')),
  created_at timestamptz not null default now(),
  primary key (plan_id, profile_id)
);

create table public.place_activity_stats (
  place_id uuid not null references public.places (id) on delete cascade,
  activity_id text not null,
  group_id uuid not null references public.groups (id),
  times_used int not null default 0,
  last_used_at timestamptz,
  primary key (place_id, activity_id, group_id)
);

create index plans_group_expires_idx on public.plans (group_id, expires_at);
create index votes_plan_idx on public.votes (plan_id);
create index profiles_group_idx on public.profiles (group_id);
