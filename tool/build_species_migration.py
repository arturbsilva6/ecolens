"""Gera a migração SQL do catálogo curado a partir do JSON revisado.

Uso (na raiz do projeto):
    python tool/build_species_migration.py

Lê supabase/data/curated_species.json e escreve
supabase/migrations/20261107050100_curated_species_catalog.sql.

A migração é reexecutável: atualiza as fichas existentes pelo slug (ou pelo
nome científico, quando o slug antigo for diferente) e insere as novas.
Nunca altera image_url, porque as fotos têm licença verificada à parte.
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ENTRADA = RAIZ / 'supabase' / 'data' / 'curated_species.json'
SAIDA = RAIZ / 'supabase' / 'migrations' / '20261107050100_curated_species_catalog.sql'

COLUNAS = [
    'slug', 'common_name', 'scientific_name', 'status', 'is_invasive',
    'species_group', 'other_names', 'main_colors', 'visual_pattern',
    'lookalikes', 'description', 'characteristics', 'habitat',
    'risk_description', 'safety_advice', 'rescue_advice', 'source_name',
    'source_url',
]


def texto(valor):
    if valor is None:
        return 'null'
    return "'" + str(valor).replace("'", "''") + "'"


def valor_sql(valor):
    if isinstance(valor, bool):
        return 'true' if valor else 'false'
    if isinstance(valor, list):
        if not valor:
            return "'{}'::text[]"
        return 'array[' + ', '.join(texto(v) for v in valor) + ']::text[]'
    return texto(valor)


def main():
    fichas = json.loads(ENTRADA.read_text(encoding='utf-8'))
    linhas = [
        '-- EcoLens: catálogo curado de fauna e flora da região de São Roque.',
        '-- GERADO por tool/build_species_migration.py a partir de',
        '-- supabase/data/curated_species.json. Não edite à mão: edite o JSON',
        '-- e gere de novo.',
        '-- Requer a migração 20261107050000_species_risk_categories.sql.',
        '',
        'begin;',
        '',
    ]
    for ficha in fichas:
        slug = texto(ficha['slug'])
        cientifico = texto(ficha['scientific_name'])
        linhas += [
            f"-- {ficha['common_name']} ({ficha['scientific_name']})",
            f'update public.species set slug = {slug}',
            f'  where scientific_name = {cientifico} and slug <> {slug}',
            f'  and not exists (select 1 from public.species s where s.slug = {slug});',
            'insert into public.species (',
            '  ' + ', '.join(COLUNAS) + ', is_published',
            ') values (',
            '  ' + ',\n  '.join(valor_sql(ficha[c]) for c in COLUNAS) + ',\n  true',
            ')',
            'on conflict (slug) do update set',
            '  ' + ',\n  '.join(
                f'{c} = excluded.{c}' for c in COLUNAS if c != 'slug'
            ) + ',\n  is_published = true;',
            '',
        ]
    linhas += ['commit;', '']
    SAIDA.write_text('\n'.join(linhas), encoding='utf-8')
    print(f'{len(fichas)} fichas -> {SAIDA.relative_to(RAIZ)}')


if __name__ == '__main__':
    main()
