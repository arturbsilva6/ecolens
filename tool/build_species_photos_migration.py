"""Gera a migração com as fotos licenciadas das espécies.

Uso (na raiz do projeto):
    python tool/build_species_photos_migration.py

Lê supabase/data/species_photos.json e escreve a migração
supabase/migrations/20261107060546_species_photo_credits.sql, que:
- cria as colunas de crédito e licença da foto;
- preenche os créditos das fotos que já existiam (pela image_url);
- define foto e créditos das fichas novas (pelo slug).

Só entram fotos com licença livre (CC0, CC BY, CC BY-SA ou domínio
público) e com autoria registrada.
"""
import json
import sys
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ENTRADA = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / 'supabase' / 'data' / 'species_photos.json'
SAIDA = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / 'supabase' / 'migrations' / '20261107060546_species_photo_credits.sql'

LICENCAS = re.compile(r'^(CC0|CC BY(-SA)? \d\.\d|Domínio público)$')
CAMPOS = ['image_credit', 'image_source_url', 'image_license_url',
          'image_license_label']


def texto(valor):
    return "'" + valor.replace("'", "''") + "'"


def validar(foto):
    assert LICENCAS.match(foto['image_license_label']), foto
    for campo in ['image_url', 'image_source_url', 'image_license_url']:
        assert foto[campo].startswith('https://'), (campo, foto)
    assert foto['image_credit'].strip(), foto


def main():
    dados = json.loads(ENTRADA.read_text(encoding='utf-8'))
    linhas = [
        '-- EcoLens: fotos licenciadas das espécies e seus créditos.',
        '-- GERADO por tool/build_species_photos_migration.py a partir de',
        f'-- supabase/data/{ENTRADA.name}. Não edite à mão.',
        '',
        'alter table public.species',
        '  add column if not exists image_credit text,',
        '  add column if not exists image_source_url text,',
        '  add column if not exists image_license_url text,',
        '  add column if not exists image_license_label text;',
        '',
        '-- Créditos das fotos que já estavam publicadas.',
    ]
    for foto in dados.get('existentes', []):
        validar(foto)
        sets = ', '.join(f'{c} = {texto(foto[c])}' for c in CAMPOS)
        linhas.append(
            f"update public.species set {sets} "
            f"where image_url = {texto(foto['image_url'])};"
        )
    linhas += ['', '-- Fotos das fichas do catálogo curado.']
    for foto in dados['novas']:
        validar(foto)
        sets = ', '.join(
            f'{c} = {texto(foto[c])}' for c in ['image_url'] + CAMPOS
        )
        linhas.append(
            f"update public.species set {sets} "
            f"where slug = {texto(foto['slug'])};"
        )
    linhas.append('')
    SAIDA.write_text('\n'.join(linhas), encoding='utf-8')
    total = len(dados.get('existentes', [])) + len(dados['novas'])
    print(f'{total} fotos -> {SAIDA}')


if __name__ == '__main__':
    main()
