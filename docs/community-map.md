# Comunidade e Mapa — revisão Android

Esta versão foi preparada na branch `feat/community-map`, baseada em `origin/feat/species-identification` (`a1705cd`). Nenhuma alteração foi aplicada no Supabase remoto; nenhuma função foi publicada. Não foram lidos segredos nem arquivos `.env`. Os registros de teste só existem nos testes automatizados e são revertidos no SQL.

## Base visual e escopo

PRs de design consultados antes da implementação: [#11](https://github.com/arturbsilva6/ecolens/pull/11) (Home, temas, Montserrat, componentes), [#12](https://github.com/arturbsilva6/ecolens/pull/12) (`feat/uiux-identification-conceito2`), [#8](https://github.com/arturbsilva6/ecolens/pull/8) e [#9](https://github.com/arturbsilva6/ecolens/pull/9). A base funcional foi mantida conforme decisão do usuário. Não houve merge, cherry-pick, cópia de componentes nem alterações nessas branches. Nenhum `AGENTS.md` foi encontrado na raiz, nos ancestrais verificados ou na árvore da base remota.

A Home só troca os destinos provisórios de Mapa, Comunidade e Fórum Local por rotas reais. Telas novas usam Material e `Theme.of(context).colorScheme`; temas, autenticação, identificação, catálogo, favoritos, histórico e SOS continuam na base existente.

## O que está implementado

- Consulta pública paginada (20 registros), filtros por hipótese de espécie e município/SP, atualização, carregamento, vazio, erro e nova tentativa.
- Publicação com conta cadastrada, foto obrigatória, data, município, observações e hipótese opcional. Sem hipótese, “Espécie não identificada”. Origem informada pelo usuário e sugestão de IA são distintas e sempre não verificadas; selecionar “IA” registra a origem declarada pelo autor, não executa análise nem comprova que houve análise.
- Autor edita data, município, hipótese/origem e observações. A foto é imutável nesta versão; para substituir, excluir e criar outro registro. Exclusão exige confirmação.
- “Meus registros” inclui rascunhos e exclusões incompletas para recuperação. Nenhum erro é apresentado como publicação/exclusão confirmada.
- Mapa OpenStreetMap, início na referência municipal de São Roque/SP, exploração de SP, filtros, marcadores agrupados por município e abertura do registro. Lista textual fornece acesso equivalente aos pontos.
- Camada de concentração usa círculos de três tamanhos (1, 2–9, 10+) e contagens dos registros **carregados**, com aviso de páginas restantes. Não é estimativa populacional, distribuição, habitat nem risco.
- Nenhum ponto ambiental com endereço/coordenadas foi inventado. Contatos existentes do SOS permanecem disponíveis; sem referência geográfica verificada, não viraram marcadores.
- Sem pedidos de GPS ou permissões novas. A opção de município é manual e funciona sem localização do dispositivo. Todos os pontos de um município compartilham uma referência municipal; ela não indica onde houve avistamento.

## Preparar o backend para testar em casa

1. Baixar a branch e revisar **antes de aplicar** `supabase/migrations/20261106134751_community_map.sql`. Ela cria duas tabelas, índices, RLS, bucket **privado**, políticas de Storage e trigger de integridade. Inclui apenas 645 referências municipais, **nenhum avistamento**.
2. Confirmar que as migrações anteriores da base já estão aplicadas. Fazer backup ou usar um projeto de teste. No Dashboard, conferir se o bucket `community-photos` e essas tabelas ainda não existem; a migração falha em colisões em vez de sobrescrever configuração existente.
3. No SQL Editor do projeto de teste, executar a migração completa dentro de uma transação (`BEGIN;`, conteúdo do arquivo, `COMMIT;`). Alternativamente, usar o fluxo de migrations da CLI já adotado pelo projeto, conferindo primeiro `supabase --help`, `supabase migration --help` e o projeto alvo. Não executar reset/push de todo o histórico sem conferir migrações pendentes. O agente não vinculou nem alterou projeto remoto.
4. Em Storage, confirmar `community-photos`: público **desligado**, limite **4 MiB**, MIME **image/png**. Não tornar o bucket público. Não adicionar políticas genéricas de escrita/leitura a todos os buckets: políticas permissivas se somam por OR e podem invalidar o isolamento desta migração. Verificar políticas antigas sobre `storage.objects`.
5. Conferir Data API expondo `public`. Os GRANTs explícitos estão na migração; anon/autenticado leem referências e publicados. Contas cadastradas escrevem somente seus próprios registros. Sessão do sign-in anônimo da IA não autoriza escrita. Não usar `user_metadata` para autorização; o servidor exige `auth.uid()` e claim assinado `is_anonymous = false`.
6. Manter configuração Auth descrita em `docs/auth-setup.md`. Para esta funcionalidade, nenhuma Edge Function nem segredo adicional é necessário.
7. Compilar usando os parâmetros **públicos existentes** `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`, conforme o seu procedimento local. Nunca colocar `service_role`, secret key, senha de banco ou segredo OAuth no aplicativo/repositório. Sem parâmetros ou migração, a tela informa indisponibilidade/configuração pendente e oferece tentativa; não usa dados de demonstração.

Verificações de configuração (somente leitura, SQL Editor):

```sql
select count(*) from public.community_municipalities; -- 645 referências, não ocorrências
select id, public, file_size_limit, allowed_mime_types
from storage.buckets where id = 'community-photos';
select tablename, policyname, roles, cmd
from pg_policies
where (schemaname = 'public' and tablename like 'community_%')
   or (schemaname = 'storage' and tablename = 'objects');
```

## Recuperação de falhas parciais

Publicação: inserir rascunho → upload de PNG em caminho UUID sem nome original → mudar para publicado. O servidor não publica antes de existir objeto. Se uma resposta se perde em qualquer etapa, não há limpeza destrutiva automática: o resultado pode ter sido confirmado no servidor. O formulário bloqueia repetir a publicação incerta e orienta voltar a “Meus registros”; a lista é recarregada. Conferir se já está publicado. Se for rascunho, excluir e criar novamente. O arquivo original nunca é enviado pelo formulário.

Exclusão: marcar `deleting` (oculta registro e foto de terceiros) → remover objeto pela **Storage API** → remover linha. A trigger proíbe remover a linha enquanto houver objeto. Se uma etapa falhar, o autor encontra a pendência em “Meus registros” e tenta excluir de novo. Storage remove permite repetir quando o objeto já não existe. Se a linha já tiver desaparecido após resposta perdida, atualizar a lista; o app não declara sucesso sem confirmação. Não remover linhas de `storage.objects` manualmente em produção: isso não apaga o arquivo físico.

Rascunhos abandonados não são apagados por job automático nesta versão. Podem ocupar armazenamento até o autor concluir a limpeza. Para revisão, acompanhar rascunhos/exclusões pendentes e consumo do bucket no Dashboard; limpezas administrativas devem usar a Storage API primeiro. Exclusão de conta e moderação/denúncia não foram acrescentadas nesta etapa.

## Privacidade e autorização

O esquema de avistamentos não possui e-mail, tokens, endereço, latitude/longitude ou GPS. Armazena apenas ID municipal; as coordenadas fixas ficam na tabela de referências. UUID de autoria é necessário para autorização, sem expor perfil/e-mail. Fotos privadas são baixadas com as políticas de Storage, sem URL pública permanente nem cache de fotos da comunidade em disco implementado pelo app.

O formulário decodifica pixels e reencoda PNG pelo engine Flutter antes do upload, descartando EXIF/XMP e metadados de localização da entrada; o nome original também não é usado. Limites: entrada até 20 MiB/40 milhões de pixels, saída até 1600 px na maior dimensão e 4 MiB. Texto/elementos visíveis na fotografia não podem ser removidos automaticamente: a UI pede que não sejam incluídos dados privados. A sanitização é do cliente oficial; o bucket não analisa metadados de clientes modificados. Storage restringe tamanho, MIME, caminho, estado e autoria, mas MIME não substitui inspeção de conteúdo.

Os caminhos e IDs são imutáveis, objetos não podem ser sobrescritos e a foto publicada não pode ser apagada antes de ocultar o registro. A função de trigger usa `SECURITY INVOKER` e `search_path` fixo, sem bypass de RLS. Fotografias e registros publicados são consultáveis por visitantes; rascunhos/pendências apenas pelo autor com conta cadastrada.

## Fonte das referências e provedor de mapa

645 municípios/SP importados de [kelvins/municipios-brasileiros](https://github.com/kelvins/municipios-brasileiros/tree/503e2f70bbf1b4b7ec0b1f68b09086ccc38fe861), revisão `503e2f70bbf1b4b7ec0b1f68b09086ccc38fe861`, consulta em 06/11/2026, licença MIT preservada em `assets/data/MUNICIPALITIES_LICENSE.txt`. Origem, revisão e hash do CSV estão em `assets/data/municipalities_source.json`. As coordenadas desse conjunto são referências municipais; não são centroides calculados pelo app nem coordenadas de ocorrências. A API oficial do IBGE foi tentada e retornou 503 neste ambiente; não se atribui a ela a verificação desta cópia. A referência de São Roque é -23.5226, -47.1357, código IBGE 3550605.

Tiles: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, identificação de cliente `br.com.ecolens`, atribuição visível dentro do mapa e link para [copyright/ODbL](https://www.openstreetmap.org/copyright). `flutter_map 8.2.2` mantém cache nativo padrão e respeita os cabeçalhos HTTP, sem prefetch/bulk download/offline forçado. [Política de tiles](https://operations.osmfoundation.org/policies/tiles/) consultada: servidor comunitário sem garantia de disponibilidade; reavaliar provedor/capacidade antes de distribuição ampla. Falha de tiles não remove a lista textual de registros e há nova tentativa. Na web, cabeçalhos de identificação/cache são geridos pelo navegador; o alvo desta revisão é Android.

Habitat/distribuição continuam apenas no catálogo com `source_name`/`source_url`; não são calculados a partir de avistamentos. Nenhuma ocorrência ou apoio ambiental fictício foi incluído.

## Reproduzir testes

Flutter instalado para esta revisão: **3.47.7**, Dart **3.13.5**. Dependências e lockfile versionados.

```sh
flutter pub get
flutter analyze
flutter test
git diff --check
```

`supabase/tests/community_rls.sql` executa cenários transacionais de visitante, sessão anônima, autor, outro usuário, escrita indevida, identidade imutável, publicação sem foto, arquivo privado, edição e exclusão em etapas, encerrando com `ROLLBACK`. Destina-se a um **banco local de teste vazio**, após a migração; não executar com dados reais porque alguns asserts verificam contagens globais.

Para PostgreSQL puro descartável, aplicar primeiro `supabase/tests/community_local_harness.sql`, depois a migração e o teste, com `psql -v ON_ERROR_STOP=1`. O harness simula os contratos mínimos Auth/Storage (roles, JWT/uid e tabelas); **não aplicar o harness ao Supabase**. Não inclui o serviço HTTP de Storage: upload/download/remoção físicos ainda precisam do teste Android com projeto Supabase configurado. Em stack Supabase local, usar Auth/Storage reais, sem harness, e repetir os testes SQL e de API.

Os testes Flutter usam SDK real com HTTP simulado para paginação, conta anônima, upload/publicação/exclusão parcial, configuração ausente e confirmação; codec real para remoção de metadados; repositório simulado para telas em 320×480, texto 2× e temas claro/escuro. Eles não comprovam entrega/retorno Android, servidor de tiles nem configuração remota.

## Resultados executados nesta entrega — 06/11/2026

| Verificação | Resultado real |
| --- | --- |
| `flutter pub get` | Sucesso; lockfile atualizado, Flutter 3.47.7 / Dart 3.13.5. |
| `flutter analyze --no-pub` | Código 0, nenhum apontamento. |
| `flutter test --no-pub` | Código 0, **191 testes passaram** na suíte completa. |
| `git diff --check` | Código 0, sem erros de whitespace. |
| Migração em PostgreSQL 17 local descartável | Aplicada com sucesso sobre harness mínimo de Auth/Storage. |
| `community_rls.sql` | Código 0, **30 asserts/negações esperadas**; `ROLLBACK` confirmado, zero avistamentos após execução. |
| Consistência municipal | 645 IDs únicos/SP, coordenadas de referência válidas; dados do app e migração gerados do mesmo CSV. |
| `supabase db advisors --type all` (CLI 3.0.0, alvo local padrão) | **Não executado**: conexão recusada em 127.0.0.1:54322, sem stack Supabase completa nessa porta. Não consultou remoto. |

A suíte cobre regressões existentes de Auth/Perfil, identificação, catálogo, favoritos, histórico e SOS, além das novas telas. Um teste de navegação legado foi atualizado porque esperava o placeholder do Fórum; agora verifica Comunidade e retorno à Home. Houve falhas intermediárias de testes durante o desenvolvimento (incluindo overflow do diálogo com fonte 2×), corrigidas antes da execução final. Não há aprovação de testes Android, TalkBack, backend remoto ou API física de Storage: permanecem pendentes para revisão em casa.

## Roteiro Android

1. `git fetch origin` e `git switch --track origin/feat/community-map` (ou `git switch feat/community-map` se já existir); `flutter pub get` e `flutter run` com seus parâmetros públicos. Não fazer merge.
2. Sem conta: Home → Comunidade/Fórum; consultar, filtrar, paginar e abrir foto. Publicar deve encaminhar ao Perfil, sem publicar. Repetir com sessão anônima da IA.
3. Conta A: publicar foto com metadados GPS conhecidos e espécie desconhecida; conferir data/município, foto e ausência de localização precisa. Publicar também hipóteses do usuário e da IA; os rótulos devem ser distintos e não científicos. Em Meus registros, editar e excluir com cancelar/confirmar.
4. Conta B: consultar o registro de A, sem ações de editar/excluir. Repetir tentativas diretas de UPDATE/DELETE e Storage com JWT de B, nunca com service_role; esperar nenhuma alteração/negação. Verificar que rascunhos/fotos de A não são acessíveis.
5. Interromper rede no upload/publicação e exclusão; reconectar e conferir Meus registros antes de repetir. Confirmar que não houve publicação sem foto, foto órfã pública ou mensagem falsa de sucesso.
6. Home → Mapa: São Roque/SP, escolher outro município, filtros, abrir registro, alternar concentração, ler legenda e carregar páginas restantes. Sem registros, o mapa não deve inventar ocorrências. Negar localização do dispositivo não bloqueia o uso; não há pedido de GPS nesta versão.
7. Repetir em 320×480, fonte 2×, claro/escuro e com teclado. Conferir câmera/galeria, Auth, identificação, catálogo, favoritos, histórico e SOS. TalkBack permanece para sua revisão final; acessibilidade não está totalmente validada.
