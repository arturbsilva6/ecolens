-- Chaves dos avatares iguais aos ícones disponíveis no app.
alter table public.public_profiles drop constraint public_profiles_avatar_check;
alter table public.public_profiles add constraint public_profiles_avatar_check
  check (avatar in ('pegada','coelho','borboleta','abelha','peixe','flor',
                    'arvore','folha','lotus','grama','montanha','sol'));
