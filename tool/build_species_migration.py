"""Gera a migração SQL do catálogo curado a partir do JSON revisado.

Uso (na raiz do projeto):
    python tool/build_species_migration.py

Lê supabase/data/curated_species.json e escreve
supabase/migrations/20261107054000_curated_species_catalog.sql.

A migração é reexecutável: atualiza as fichas existentes pelo slug (ou pelo
nome científico, quando o slug antigo for diferente) e insere as novas.
Nunca altera image_url, porque as fotos têm licença verificada à parte.
"""
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ENTRADA = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / 'supabase' / 'data' / 'curated_species.json'
SAIDA = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / 'supabase' / 'migrations' / '20261107054000_curated_species_catalog.sql'

COLUNAS = [
    'slug', 'common_name', 'scientific_name', 'status', 'is_invasive',
    'species_group', 'other_names', 'main_colors', 'visual_pattern',
    'lookalikes', 'description', 'characteristics', 'habitat',
    'risk_description', 'safety_advice', 'rescue_advice', 'source_name',
    'source_url',
]


def main():
    fichas = json.loads(ENTRADA.read_text(encoding='utf-8'))
    dados = [{c: f[c] for c in COLUNAS} for f in fichas]
    conteudo = json.dumps(dados, ensure_ascii=False, separators=(',', ':'))
    marcador = '$ecolens$'
    assert marcador not in conteudo
    tipos = {
        'is_invasive': 'boolean',
        'other_names': 'text[]',
        'main_colors': 'text[]',
        'lookalikes': 'text[]',
    }
    definicao = ', '.join(f'{c} {tipos.get(c, "text")}' for c in COLUNAS)
    atualizacao = ',\n  '.join(
        f'{c} = excluded.{c}' for c in COLUNAS if c != 'slug'
    )
    sql = f"""-- EcoLens: catálogo curado de fauna e flora da região de São Roque.
-- GERADO por tool/build_species_migration.py a partir de
-- supabase/data/{ENTRADA.name}. Não edite à mão: edite o JSON
-- e gere de novo.
-- Requer a migração 20261107053746_species_risk_categories.sql.
--
-- Reexecutável: atualiza as fichas existentes pelo slug (ou pelo nome
-- científico, quando o slug antigo for diferente) e insere as novas.
-- Nunca altera image_url, porque as fotos têm licença verificada à parte.

create temporary table curated_species on commit drop as
select * from jsonb_to_recordset({marcador}{conteudo}{marcador}::jsonb)
  as d({definicao});

update public.species s
set slug = d.slug
from curated_species d
where s.scientific_name = d.scientific_name
  and s.slug <> d.slug
  and not exists (select 1 from public.species x where x.slug = d.slug);

insert into public.species ({', '.join(COLUNAS)}, is_published)
select {', '.join('d.' + c for c in COLUNAS)}, true
from curated_species d
on conflict (slug) do update set
  {atualizacao},
  is_published = true;
"""
    SAIDA.write_text(sql, encoding='utf-8')
    print(f'{len(fichas)} fichas -> {SAIDA} ({len(sql)} bytes)')


if __name__ == '__main__':
    main()
