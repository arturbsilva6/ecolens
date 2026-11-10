-- EcoLens: perfil público opcional (nome e avatar do app, sem foto).
-- Aparece como autor nos avistamentos. Apagado junto com a conta.
create table public.public_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null
    check (char_length(btrim(display_name)) between 2 and 30
           and display_name !~ '[<>[:cntrl:]]'),
  avatar text not null
    check (avatar in ('onca','passaro','borboleta','abelha','sapo','peixe',
                      'flor','arvore','folha','cogumelo','montanha','sol')),
  updated_at timestamptz not null default now()
);

alter table public.public_profiles enable row level security;
revoke all on public.public_profiles from anon, authenticated;
grant select on public.public_profiles to anon, authenticated;
grant insert, update, delete on public.public_profiles to authenticated;

create policy public_profiles_read on public.public_profiles
  for select to anon, authenticated using (true);
create policy public_profiles_insert on public.public_profiles
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and (select auth.jwt()->>'is_anonymous') = 'false');
create policy public_profiles_update on public.public_profiles
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid())
              and (select auth.jwt()->>'is_anonymous') = 'false');
create policy public_profiles_delete on public.public_profiles
  for delete to authenticated using (user_id = (select auth.uid()));
