create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  full_name text not null,
  association_name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.maraudes (
  id uuid primary key default gen_random_uuid(),
  association_name text not null,
  location text not null,
  address text not null,
  date date not null,
  start_time time not null,
  end_time time not null,
  estimated_plates integer not null check (estimated_plates > 0),
  distribution_type text not null default 'Standard',
  comment text not null default '',
  latitude double precision not null,
  longitude double precision not null,
  status text not null default 'planned'
    check (status in ('planned', 'ongoing', 'completed')),
  created_by uuid references auth.users (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_maraudes_updated_at on public.maraudes;
create trigger set_maraudes_updated_at
before update on public.maraudes
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.maraudes enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "maraudes_select_authenticated" on public.maraudes;
create policy "maraudes_select_authenticated"
on public.maraudes
for select
to authenticated
using (true);

drop policy if exists "maraudes_insert_same_association" on public.maraudes;
create policy "maraudes_insert_same_association"
on public.maraudes
for insert
to authenticated
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.association_name = maraudes.association_name
  )
);

drop policy if exists "maraudes_update_same_association" on public.maraudes;
create policy "maraudes_update_same_association"
on public.maraudes
for update
to authenticated
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.association_name = maraudes.association_name
  )
)
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.association_name = maraudes.association_name
  )
);

drop policy if exists "maraudes_delete_same_association" on public.maraudes;
create policy "maraudes_delete_same_association"
on public.maraudes
for delete
to authenticated
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = (select auth.uid())
      and profiles.association_name = maraudes.association_name
  )
);
