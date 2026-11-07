-- Local PostgreSQL ONLY: minimal Auth/Storage contracts, NOT production setup.
-- Run in a disposable blank database, then migration and community_rls.sql.
create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema storage;
create table auth.users(id uuid primary key);
create function auth.jwt() returns jsonb language sql stable as
 $$ select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb $$;
create function auth.uid() returns uuid language sql stable as
 $$ select (auth.jwt()->>'sub')::uuid $$;
grant usage on schema auth, storage to anon, authenticated;
grant execute on function auth.uid(), auth.jwt() to anon, authenticated;
create table storage.buckets(id text primary key, name text, public boolean,
 file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),
 bucket_id text references storage.buckets(id), name text not null, unique(bucket_id,name));
alter table storage.objects enable row level security;
grant select, insert, update, delete on storage.objects to anon, authenticated;
