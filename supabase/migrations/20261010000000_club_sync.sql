-- Veritas Tennis club sync.
--
-- Each club is identified by a random code that members share (e.g. in the
-- club WhatsApp group). The code is the only credential: tables are not
-- reachable through the REST API at all; the app goes through the three
-- security-definer functions below, which require a valid club code.

create table if not exists public.clubs (
  code       text primary key,
  name       text not null check (char_length(name) between 2 and 80),
  created_at timestamptz not null default now()
);

create table if not exists public.club_records (
  club_code  text not null references public.clubs (code) on delete cascade,
  kind       text not null check (kind in ('player', 'match', 'tournament')),
  id         text not null check (char_length(id) between 1 and 64),
  data       jsonb,
  deleted    boolean not null default false,
  updated_at timestamptz not null default clock_timestamp(),
  primary key (club_code, kind, id)
);

create index if not exists club_records_changes on public.club_records (club_code, updated_at);

alter table public.clubs enable row level security;
alter table public.club_records enable row level security;
-- No policies: anon and authenticated roles cannot touch the tables directly.
revoke all on public.clubs, public.club_records from anon, authenticated;

-- Creates a club and returns its shareable code, e.g. "KQ7MZ-3HXPA".
create or replace function public.create_club(p_name text)
returns table (code text, name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_bytes bytea;
  v_code text;
  v_name text := trim(coalesce(p_name, ''));
  v_positions constant int[] := array[0, 1, 2, 3, 4, 5, 9, 10, 11, 12]; -- fully random bytes of a v4 UUID
  i int;
begin
  if char_length(v_name) < 2 or char_length(v_name) > 80 then
    raise exception 'Club name must be 2 to 80 characters';
  end if;
  loop
    v_bytes := decode(replace(gen_random_uuid()::text, '-', ''), 'hex');
    v_code := '';
    for i in 1 .. 10 loop
      v_code := v_code || substr(v_alphabet, get_byte(v_bytes, v_positions[i]) % 31 + 1, 1);
      if i = 5 then v_code := v_code || '-'; end if;
    end loop;
    exit when not exists (select 1 from public.clubs c where c.code = v_code);
  end loop;
  insert into public.clubs (code, name) values (v_code, v_name);
  return query select v_code, v_name;
end;
$$;

-- Returns the club's name, or nothing if the code is wrong.
create or replace function public.get_club(p_code text)
returns table (code text, name text)
language sql
stable
security definer
set search_path = public
as $$
  select c.code, c.name from public.clubs c where c.code = upper(trim(p_code));
$$;

-- Upserts a batch of records: [{kind, id, data, deleted}, ...]. Last write wins.
create or replace function public.sync_push(p_code text, p_records jsonb)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := upper(trim(p_code));
  r jsonb;
begin
  if not exists (select 1 from public.clubs c where c.code = v_code) then
    raise exception 'Club not found' using errcode = 'P0002';
  end if;
  if jsonb_typeof(p_records) <> 'array' or jsonb_array_length(p_records) > 500 then
    raise exception 'Send between 0 and 500 records at a time';
  end if;
  for r in select * from jsonb_array_elements(p_records) loop
    if octet_length(coalesce(r -> 'data', 'null'::jsonb)::text) > 200000 then
      raise exception 'Record % is too large', r ->> 'id';
    end if;
    insert into public.club_records as cr (club_code, kind, id, data, deleted, updated_at)
    values (
      v_code,
      r ->> 'kind',
      r ->> 'id',
      case when coalesce((r ->> 'deleted')::boolean, false) then null else r -> 'data' end,
      coalesce((r ->> 'deleted')::boolean, false),
      clock_timestamp()
    )
    on conflict (club_code, kind, id) do update
      set data = excluded.data, deleted = excluded.deleted, updated_at = excluded.updated_at;
  end loop;
  return clock_timestamp();
end;
$$;

-- Records changed after p_since (all records when null), oldest first.
create or replace function public.sync_pull(p_code text, p_since timestamptz default null, p_limit int default 1000)
returns table (kind text, id text, data jsonb, deleted boolean, updated_at timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_code text := upper(trim(p_code));
begin
  if not exists (select 1 from public.clubs c where c.code = v_code) then
    raise exception 'Club not found' using errcode = 'P0002';
  end if;
  return query
    select cr.kind, cr.id, cr.data, cr.deleted, cr.updated_at
    from public.club_records cr
    where cr.club_code = v_code and (p_since is null or cr.updated_at > p_since)
    order by cr.updated_at, cr.kind, cr.id
    limit least(greatest(coalesce(p_limit, 1000), 1), 1000);
end;
$$;

revoke all on function public.create_club(text) from public;
revoke all on function public.get_club(text) from public;
revoke all on function public.sync_push(text, jsonb) from public;
revoke all on function public.sync_pull(text, timestamptz, int) from public;
grant execute on function public.create_club(text) to anon, authenticated;
grant execute on function public.get_club(text) to anon, authenticated;
grant execute on function public.sync_push(text, jsonb) to anon, authenticated;
grant execute on function public.sync_pull(text, timestamptz, int) to anon, authenticated;
