-- EcoLens: grupo das quatro fichas anteriores à curadoria, para o filtro
-- Animais/Plantas do catálogo.
update public.species set species_group = 'planta'
where scientific_name in ('Handroanthus albus', 'Leucaena leucocephala')
  and species_group is null;
update public.species set species_group = 'ave'
where scientific_name = 'Ramphastos toco' and species_group is null;
update public.species set species_group = 'mamifero'
where scientific_name = 'Callithrix jacchus' and species_group is null;
