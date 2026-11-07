-- Transactional regression tests. Fixtures are rolled back, never real sightings.
-- For a local Supabase stack, run with psql as postgres after the migration.
begin;
insert into auth.users(id) values
 ('10000000-0000-4000-8000-000000000001'),
 ('10000000-0000-4000-8000-000000000002'),
 ('10000000-0000-4000-8000-000000000003');
create function pg_temp.assert_true(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'FAILED: %',label; end if; end $$;
create function pg_temp.must_fail(statement text, label text) returns void language plpgsql as $$
begin
 begin execute statement;
 exception when insufficient_privilege or check_violation or not_null_violation or foreign_key_violation then return;
 end;
 raise exception 'FAILED: expected denial: %',label;
end $$;
set local request.jwt.claims = '{}';
set local role anon;
select pg_temp.assert_true((select count(*)=645 from public.community_municipalities),'municipalities readable');
select pg_temp.must_fail($q$insert into public.community_sightings(id) values(gen_random_uuid())$q$,'visitor cannot insert');
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000003","is_anonymous":true}';
set local role authenticated;
select pg_temp.must_fail($q$insert into public.community_sightings
 (id,owner_id,municipality_id,observed_on,identification_origin,photo_path)
 values('20000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000003','3550605',current_date,'unknown',
 '10000000-0000-4000-8000-000000000003/20000000-0000-4000-8000-000000000003/photo.png')$q$,'anonymous session cannot insert');
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","is_anonymous":false}';
set local role authenticated;
insert into public.community_sightings(id,owner_id,municipality_id,observed_on,identification_origin,photo_path)
 values('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','3550605',current_date,'unknown',
 '10000000-0000-4000-8000-000000000001/20000000-0000-4000-8000-000000000001/photo.png');
select pg_temp.must_fail($q$update public.community_sightings set status='published'$q$,'cannot publish without image');
insert into storage.objects(bucket_id,name) values ('community-photos',
 '10000000-0000-4000-8000-000000000001/20000000-0000-4000-8000-000000000001/photo.png');
select pg_temp.assert_true((select count(*)=1 from storage.objects where bucket_id='community-photos'),'author reads draft image');
select pg_temp.must_fail($q$delete from public.community_sightings$q$,'cannot orphan image');
select pg_temp.must_fail($q$update public.community_sightings set owner_id='10000000-0000-4000-8000-000000000002'$q$,'cannot reassign owner');
select pg_temp.must_fail($q$update public.community_sightings set id=gen_random_uuid()$q$,'immutable identity');
select pg_temp.must_fail($q$update public.community_sightings set municipality_id='9999999'$q$,'municipality validated');
select pg_temp.must_fail($q$update public.community_sightings set observed_on=current_date+1$q$,'future date rejected');
select pg_temp.must_fail($q$update public.community_sightings set species_label='Jararaca'$q$,'identification origin consistent');
reset role;
set local request.jwt.claims = '{}';
set local role anon;
select pg_temp.assert_true((select count(*)=0 from public.community_sightings),'draft hidden from visitor');
select pg_temp.assert_true((select count(*)=0 from storage.objects where bucket_id='community-photos'),'draft image hidden from visitor');
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","is_anonymous":false}';
set local role authenticated;
select pg_temp.assert_true((select count(*)=0 from public.community_sightings),'draft hidden from other user');
select pg_temp.must_fail($q$insert into storage.objects(bucket_id,name) values('community-photos','10000000-0000-4000-8000-000000000001/arbitrary.png')$q$,'cannot upload in another folder');
with changed as (update public.community_sightings set notes='attack' returning id) select pg_temp.assert_true(count(*)=0,'other user cannot update') from changed;
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","is_anonymous":false}';
set local role authenticated;
update public.community_sightings set status='published';
update public.community_sightings set notes='Updated by author',species_label='Hipótese',identification_origin='user';
select pg_temp.assert_true((select notes='Updated by author' from public.community_sightings),'author edits published');
with changed as (delete from storage.objects where bucket_id='community-photos' returning id) select pg_temp.assert_true(count(*)=0,'published image protected from premature deletion') from changed;
with changed as (update storage.objects set name='replacement' where bucket_id='community-photos' returning id) select pg_temp.assert_true(count(*)=0,'object overwrite forbidden') from changed;
reset role;
set local request.jwt.claims = '{}';
set local request.jwt.claims = '{}';
set local role anon;
select pg_temp.assert_true((select count(*)=1 from public.community_sightings),'visitor reads published');
select pg_temp.assert_true((select count(*)=1 from storage.objects where bucket_id='community-photos'),'visitor reads published image');
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000002","is_anonymous":false}';
set local role authenticated;
with changed as (update public.community_sightings set notes='attack' returning id) select pg_temp.assert_true(count(*)=0,'other user cannot edit published') from changed;
with changed as (delete from public.community_sightings returning id) select pg_temp.assert_true(count(*)=0,'other user cannot delete published') from changed;
with changed as (delete from storage.objects where bucket_id='community-photos' returning id) select pg_temp.assert_true(count(*)=0,'other user cannot delete image') from changed;
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000003","is_anonymous":true}';
set local role authenticated;
select pg_temp.assert_true((select count(*)=1 from public.community_sightings),'anonymous reads published');
with changed as (update public.community_sightings set notes='attack' returning id) select pg_temp.assert_true(count(*)=0,'anonymous cannot edit') from changed;
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","is_anonymous":false}';
set local role authenticated;
update public.community_sightings set status='deleting';
select pg_temp.must_fail($q$update public.community_sightings set status='published'$q$,'cannot restore deleting row');
reset role;
set local request.jwt.claims = '{}';
set local request.jwt.claims = '{}';
set local role anon;
select pg_temp.assert_true((select count(*)=0 from public.community_sightings),'deleting hidden');
select pg_temp.assert_true((select count(*)=0 from storage.objects where bucket_id='community-photos'),'deleting image hidden');
reset role;
set local request.jwt.claims = '{"sub":"10000000-0000-4000-8000-000000000001","is_anonymous":false}';
set local role authenticated;
delete from storage.objects where bucket_id='community-photos';
delete from public.community_sightings;
select pg_temp.assert_true((select count(*)=0 from public.community_sightings),'author completes deletion');
rollback;
