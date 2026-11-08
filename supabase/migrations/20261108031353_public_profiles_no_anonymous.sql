-- Sessões anônimas (usadas só para a IA) não alteram perfis públicos.
alter policy public_profiles_update on public.public_profiles
  using (user_id = (select auth.uid())
         and (select auth.jwt()->>'is_anonymous') = 'false');
alter policy public_profiles_delete on public.public_profiles
  using (user_id = (select auth.uid())
         and (select auth.jwt()->>'is_anonymous') = 'false');
