-- BOARD GAME LOUNGE: Supabase database setup
-- Run this entire file in Supabase > SQL Editor > New query > Run.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'สมาชิก',
  style text not null default 'เล่นชิล ๆ',
  favorite_game text not null default 'Dixit',
  role text not null default 'member' check (role in ('member','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  game text not null,
  max_players integer not null default 4 check (max_players between 2 and 12),
  style text not null default 'เล่นชิล ๆ',
  host_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.room_members (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_date date not null,
  description text not null default '',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Create a profile automatically whenever someone signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'สมาชิก')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Admin check that avoids recursive RLS policy evaluation.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

-- A user cannot promote themselves by editing their own profile.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role
     and not public.is_admin() then
    raise exception 'You are not allowed to change your role';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_role_trigger on public.profiles;
create trigger protect_profile_role_trigger
before update on public.profiles
for each row execute procedure public.protect_profile_role();

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.events enable row level security;

-- Profiles: signed-in members can see the community directory; users edit only themselves.
drop policy if exists "Profiles are viewable by authenticated users" on public.profiles;
create policy "Profiles are viewable by authenticated users"
on public.profiles for select to authenticated using (true);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
on public.profiles for update to authenticated
using (id = (select auth.uid()) or public.is_admin())
with check (id = (select auth.uid()) or public.is_admin());

-- Rooms can be browsed; only signed-in users can create one.
drop policy if exists "Rooms are viewable by everyone" on public.rooms;
create policy "Rooms are viewable by everyone"
on public.rooms for select to anon, authenticated using (true);

drop policy if exists "Signed in users create rooms" on public.rooms;
create policy "Signed in users create rooms"
on public.rooms for insert to authenticated
with check (host_id = (select auth.uid()));

drop policy if exists "Host or admin updates rooms" on public.rooms;
create policy "Host or admin updates rooms"
on public.rooms for update to authenticated
using (host_id = (select auth.uid()) or public.is_admin())
with check (host_id = (select auth.uid()) or public.is_admin());

drop policy if exists "Host or admin deletes rooms" on public.rooms;
create policy "Host or admin deletes rooms"
on public.rooms for delete to authenticated
using (host_id = (select auth.uid()) or public.is_admin());

-- Room membership: each signed-in user can join themselves; host/admin can remove members.
drop policy if exists "Room members are viewable" on public.room_members;
create policy "Room members are viewable"
on public.room_members for select to anon, authenticated using (true);

drop policy if exists "Users join as themselves" on public.room_members;
create policy "Users join as themselves"
on public.room_members for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "User leaves or admin removes membership" on public.room_members;
create policy "User leaves or admin removes membership"
on public.room_members for delete to authenticated
using (user_id = (select auth.uid()) or public.is_admin()
       or exists (select 1 from public.rooms r
                  where r.id = room_id and r.host_id = (select auth.uid())));

-- Events are readable by everyone; only admins manage them.
drop policy if exists "Events are viewable by everyone" on public.events;
create policy "Events are viewable by everyone"
on public.events for select to anon, authenticated using (true);

drop policy if exists "Admins create events" on public.events;
create policy "Admins create events"
on public.events for insert to authenticated
with check (public.is_admin());

drop policy if exists "Admins update events" on public.events;
create policy "Admins update events"
on public.events for update to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins delete events" on public.events;
create policy "Admins delete events"
on public.events for delete to authenticated
using (public.is_admin());

-- Allow the browser client to use these tables.
grant usage on schema public to anon, authenticated;
grant select on public.rooms, public.room_members, public.events to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant insert, update, delete on public.rooms to authenticated;
grant select, insert, delete on public.room_members to authenticated;
grant insert, update, delete on public.events to authenticated;
