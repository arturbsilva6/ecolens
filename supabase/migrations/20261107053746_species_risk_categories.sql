-- EcoLens: categorias de risco e campos do guia de identificação.
--
-- Novas classificações:
--   danger   = perigoso: risco de morte ou sequela
--   caution  = cautela: dor ou reação forte, ou risco que depende de contato
--   harmless = inofensivo
-- 'invasive' e 'unverified' continuam aceitos para os registros antigos.
-- Ser invasora passa a ser independente do risco (is_invasive).

alter table public.species drop constraint if exists species_status_check;
alter table public.species
  add constraint species_status_check
  check (status in ('danger', 'caution', 'harmless', 'invasive', 'unverified'));

alter table public.species
  add column if not exists is_invasive boolean not null default false,
  add column if not exists species_group text,
  add column if not exists other_names text[] not null default '{}',
  add column if not exists main_colors text[] not null default '{}',
  add column if not exists visual_pattern text,
  add column if not exists lookalikes text[] not null default '{}',
  add column if not exists rescue_advice text;

alter table public.species drop constraint if exists species_group_check;
alter table public.species
  add constraint species_group_check
  check (
    species_group is null or species_group in (
      'serpente', 'aranha', 'escorpiao', 'lagarta', 'inseto', 'mamifero',
      'ave', 'reptil', 'anfibio', 'planta', 'molusco'
    )
  );

update public.species set is_invasive = true where status = 'invasive';

-- A leitura continua restrita às fichas publicadas pela política existente
-- "Read published species"; as colunas novas herdam o grant de select.
