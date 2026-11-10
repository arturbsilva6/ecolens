-- Remove o backup temporário feito antes da revisão do catálogo (07/11/2026).
-- O catálogo atual (66 espécies) está nas migrações do repositório.
drop table if exists private.species_backup_20261107;
