# Catálogo curado de espécies

O catálogo regional tem **50 fichas** de fauna e flora da região de São Roque
(Araçariguama, Ibiúna, Mairinque, Vargem Grande Paulista, Alumínio e Cotia).

## Categorias de risco

| Status | Tag no app | Critério |
|---|---|---|
| `danger` | Perigo (vermelho) | Risco de morte ou sequela |
| `caution` | Cautela (laranja) | Dor ou reação forte, ou risco que depende de contato (ex.: raiva em morcegos) |
| `harmless` | Inofensiva (verde) | Sem risco relevante |

Ser **invasora** é independente do risco (`is_invasive`). `invasive` e
`unverified` continuam aceitos para os registros antigos.

## Origem e revisão

1. As fichas foram rascunhadas com o Gemini em 5 lotes, a partir de um prompt
   com regras de segurança (fontes oficiais, sem práticas proibidas de
   primeiros socorros).
2. Cada lote foi revisado. Correções aplicadas, entre outras:
   - "CIATox 0800 722 6001" virou **Disque-Intoxicação 0800 722 6001** (o
     número é nacional; CIATox são os centros regionais);
   - raiva (morcegos, cachorro-do-mato) e febre maculosa encaminham para a
     unidade de saúde, não para o Disque-Intoxicação;
   - abelhas: orientação dos Bombeiros (local fechado, sem pular na água) no
     lugar de "correr em zigue-zague"; removida a afirmação de que o soro
     antiapílico já está no SUS (estava em fase 3 em out/2025);
   - caramujo-africano: descarte conforme a Nota Técnica nº 30/2022 do
     Ministério da Saúde;
   - viúva-negra: espécie urbana comum em SP (*Latrodectus geometricus*);
   - onça-pintada e tamanduá-bandeira: o texto deixa claro que não há
     registros confirmados recentes na região;
   - tamanhos de aranhas, nomes populares errados e afirmações sem fonte.
3. Cinco mamíferos sem orientação crítica de segurança ficaram sem link
   oficial (`source_url` vazio).

O arquivo revisado é `supabase/data/curated_species.json`; o campo
`review_notes` guarda o motivo das correções e não vai para o banco.

## Como aplicar no Supabase

No **SQL Editor** do painel, execute nesta ordem:

1. `supabase/migrations/20261107050000_species_risk_categories.sql`
2. `supabase/migrations/20261107050100_curated_species_catalog.sql`

A segunda é reexecutável: atualiza as fichas existentes pelo slug (ou pelo
nome científico) e insere as novas, **sem alterar `image_url`**.

O app funciona antes e depois da migração: se as colunas novas não existirem,
ele lê só as antigas.

## Como editar ou acrescentar fichas

Edite `supabase/data/curated_species.json` e gere a migração de novo:

```bash
python tool/build_species_migration.py
```
