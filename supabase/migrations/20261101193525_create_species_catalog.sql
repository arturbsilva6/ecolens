-- EcoLens: migração inicial já aplicada ao banco remoto.
-- RLS protege o catálogo; apenas espécies publicadas podem ser consultadas.

create table public.species (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique,
 common_name text not null,
 scientific_name text not null,
 status text not null default 'unverified' check (status in ('danger','invasive','unverified')),
 description text,
 characteristics text,
 habitat text,
 risk_description text,
 safety_advice text,
 source_name text,
 source_url text,
 image_url text,
 is_published boolean not null default false,
 created_at timestamptz not null default now()
);
alter table public.species enable row level security;
revoke all on table public.species from anon, authenticated;
grant select on table public.species to anon, authenticated;
create policy "Read published species" on public.species for select to anon, authenticated using (is_published = true);
