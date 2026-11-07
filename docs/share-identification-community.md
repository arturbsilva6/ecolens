# Compartilhar identificação na comunidade — issue #14

Implementação de [#14](https://github.com/arturbsilva6/ecolens/issues/14), dependente do [PR #13](https://github.com/arturbsilva6/ecolens/pull/13), ainda em rascunho ao iniciar. Branch `feat/share-identification-community`, criada de `origin/feat/community-map` atualizada, base `a4a34cb`. Destino do PR: `feat/community-map`, sem merge. Não houve alteração, integração nem cópia de componentes das branches de design #8, #9, #11 e #12. Nenhum `AGENTS.md` foi encontrado nos locais verificados. Nenhum segredo ou `.env` foi lido/incluído.

## Fluxo e regras

1. O resultado real da IA oferece **Compartilhar na comunidade**, abrindo o formulário existente. O resultado original permanece na rota anterior; histórico e favoritos não recebem alterações por compartilhar/cancelar/publicar.
2. `CommunityIdentificationSeed` transporta em memória a fotografia escolhida para análise e a hipótese disponível (nomes comum/científico quando cabem no campo). Não transporta imagem do catálogo, data de captura, EXIF, GPS ou município. Resultado inconclusivo começa como espécie não identificada. Resultado demonstrativo não oferece compartilhamento; o caminho demonstrativo existente continua na ficha de demonstração.
3. O formulário aplica `CommunityPhotoService` à foto antes de qualquer envio. Foto ausente, inválida ou perdida durante seleção gera orientação para escolher outra, sem usar foto do catálogo. A seleção passa pela mesma sanitização e limites do PR #13. Abrir o formulário e preparar a imagem **não** cria registros nem faz upload.
4. A data do avistamento começa sem preenchimento no compartilhamento. O usuário escolhe uma data ou aciona explicitamente **Usar hoje como data do avistamento**; não se afirma que hoje é a data de captura. Município/SP também exige escolha manual. Mantém-se somente referência municipal.
5. A hipótese recebida começa com origem **Sugerida por IA**, sempre não verificada. Ao editar o texto, a origem passa a **Informada por mim**. É possível escolher **Espécie não identificada**; nesse caso, a hipótese é enviada como nula. Observações não são preenchidas automaticamente com explicações da IA.
6. Ao tocar **Publicar**, há validação dos campos e da sessão. Convidado, sessão anônima ou sessão expirada não autorizam escrita. O formulário abre a rota única de Perfil e fica montado sob ela, com foto e campos preservados. O SDK é relido para evitar apresentar conta anônima/expirada como perfil cadastrado. Não foram alterados PKCE, redirects, provedores nem a validação de callbacks.
7. Após um novo login por e-mail ou conclusão do Google, o Perfil retorna ao formulário. Há também **Voltar ao avistamento** para cancelar/retornar. Uma rota já aberta é reutilizada quando chegam callbacks; erro/recuperação não empilham outro Perfil. **Nenhuma publicação é disparada pelo login**: o usuário revisa e toca **Publicar** novamente. A sessão é conferida novamente nesse envio, no repositório e pela autorização do servidor.
8. O envio tem bloqueio síncrono contra duplo toque. O repositório mantém as etapas rascunho → upload privado → publicação e retorna a linha realmente confirmada pelo servidor. Se o resultado for incerto, mantém-se o bloqueio para não repetir, com acesso a **Conferir Meus registros**, inclusive quando o formulário foi aberto a partir do resultado.
9. Após confirmação, são oferecidos **Ver avistamento publicado**, **Ver comunidade**, **Ver no mapa** e **Concluir**. Comunidade/mapa fazem consultas novas; o mapa aberto nessa ação filtra pelo município do registro. Não são criados marcadores ou ocorrências de demonstração.
10. Voltar/cancelar um formulário com dados editados exige confirmação de descarte. Recusar mantém os campos; confirmar volta ao resultado sem modificá-lo. Durante preparação/envio/login em andamento, o formulário evita descarte por uma segunda navegação involuntária.

## Arquitetura e arquivos

- `lib/models/community_identification_seed.dart`: transporte e regra de preenchimento da hipótese, sem persistência ou localização inferida.
- `lib/screens/identification/identification_result_screen.dart`: ação de compartilhar, proteção para demonstração e tratamento de fotografia ausente. Repositório, sanitizador e acesso à conta podem ser injetados em testes.
- `lib/screens/community/sighting_form_screen.dart`: reutilização do formulário, sanitização, seleção, revisão de data/município, origem, retomada do login, descarte e pós-publicação. Seleção de foto e acesso à conta têm injeção para testar falhas sem integração falsa.
- `lib/data/community_repository.dart` e `supabase_community_repository.dart`: `create` passa a devolver `Sighting`, usando a resposta da atualização já existente; rejeita sessão anônima/expirada antes da escrita. **Sem endpoint, função, tabela, migração ou política nova.**
- `lib/widgets/auth/account_navigation_scope.dart`, `lib/app.dart`: disponibilizam a navegação única de Perfil ao fluxo e aguardam seu retorno. `AuthController.synchronizeSession` relê o estado do SDK sem limpar callbacks/dados locais.
- `lib/screens/profile/profile_screen.dart`, `lib/data/supabase_auth_repository.dart`: retorno opcional ao avistamento após login; sessão anônima/expirada continua como convidado. O retorno só fecha o Perfil se ele ainda for a rota atual e a sessão de conta estiver utilizável.
- `lib/screens/community/community_screen.dart`, `lib/screens/map/heat_map_screen.dart`: entrada opcional em Meus registros e município inicial para consulta após publicação.
- Testes: `test/share_identification_community_test.dart`, `test/supabase_auth_repository_test.dart`, `test/supabase_community_repository_test.dart` e `test/support/community_fake.dart`.

## Estado, privacidade e recuperação

Durante o fluxo ativo, o rascunho pertence à rota. A correção local de retorno OAuth acrescenta um checkpoint temporário, com foto já sanitizada e campos revisados, **antes de abrir a conta**. Ele permite retomar o formulário após um novo processo, sem publicação automática. Não se registram dados do formulário, tokens ou URLs de callback em logs; o SDK continua responsável por sessão/PKCE.

**Há retomada local por até 24 horas para o snapshot anterior ao login**, inclusive sem sessão ou com cancelamento/erro. Ele é removido ao retornar do Perfil no fluxo ativo, descartar ou antes de tentar publicar; itens expirados são removidos na próxima leitura. Não é autosave contínuo: encerramento antes da gravação, limpeza de dados e reinstalação ainda podem perder o formulário. O histórico textual continua sem guardar fotografias. Consulte as evidências e os limites em [oauth-sharing-return.md](oauth-sharing-return.md).

Se o processo/rede falhar **após** a ação Publicar, o pedido pode ter sido confirmado no servidor. Conferir Meus registros antes de iniciar outro envio. A recuperação de rascunhos e exclusões remotas continua a do [guia do PR #13](community-map.md); não há reenvio automático, limpeza destrutiva nem anúncio de sucesso sem linha confirmada. As políticas de autoria e o bucket privado permanecem os mesmos.

## Resultados automatizados — 06/11/2026

Ambiente: Flutter **3.47.7**, Dart **3.13.5**, SDK instalado fora do PATH em `/workspace/work/flutter`. Nenhuma dependência nova.

- `flutter analyze --no-pub`: código 0, nenhum apontamento.
- `flutter test --no-pub`: código 0, **216 testes aprovados** na suíte completa (191 da base e 25 novos).
- `flutter test --no-pub test/share_identification_community_test.dart`: código 0, **23 cenários aprovados**, incluindo a verificação dirigida final que começa no resultado com ficha correspondente em 320×480/texto 2×, claro/escuro.
- `git diff --check`: código 0, sem erros. Conferência do índice também realizada antes do commit.

Cobertura nova: preenchimento/foto original, foto ausente/inválida e nova seleção, demonstração, data explicitamente escolhida, hipótese/origem e espécie desconhecida, convidados, sessão anônima/expirada no SDK, login e cancelamento, callbacks sem duplicar Perfil, duplo envio, publicação incerta, abertura do publicado/mapa e preservação efetiva de histórico/favoritos. A suíte mantém testes anteriores de Auth/PKCE, IA, catálogo, SOS, favoritos, histórico, Comunidade, Mapa e codecs PNG/JPEG com metadados de localização.

Os cenários usam injeção: repositório/serviço de foto controlados na navegação; AuthController e telas reais com repositório Auth simulado para e-mail/Google/cancelamento/callback; SDK Supabase real com HTTP simulado para sessão e persistência. A sanitização real continua coberta pelos testes do PR #13. **Isso não comprova login Google no navegador Android, upload físico, tiles ou configuração remota.** Não foram executados testes SQL novos porque o esquema/políticas não mudaram; os resultados SQL anteriores pertencem ao PR #13.

## Roteiro Android

**Validação manual do retorno do login concluída em 06/11/2026**, conforme relatado pelo usuário no Android: sucesso, cancelamento e encerramento do processo durante o login. Detalhes em [oauth-sharing-return.md](oauth-sharing-return.md). Os demais itens deste roteiro não fazem parte desse registro.

1. Preparar o backend do PR #13 seguindo [community-map.md](community-map.md), se ainda não estiver configurado. Este PR não aplica SQL, não habilita IA, não publica funções e não exige segredo ou configuração nova. Para alcançar um resultado real da IA, a configuração existente de reconhecimento precisa estar disponível: consultar [AI_RECOGNITION.md](AI_RECOGNITION.md). Se só houver demonstração habilitada, ela deve continuar sem ação de compartilhar como resultado real.
2. Baixar a branch: `git fetch origin feat/share-identification-community:refs/remotes/origin/feat/share-identification-community` e `git switch --track origin/feat/share-identification-community` (ou `git switch feat/share-identification-community` se já existir). Rodar `flutter pub get` e iniciar no emulador com os parâmetros públicos/flags existentes já configurados para seu projeto. Não fazer merge.
3. Com foto própria e resultado real, tocar Compartilhar. Conferir que veio a foto escolhida, não uma ilustração do catálogo, e que o rótulo continua sugestão não verificada. Data e município devem exigir revisão. Corrigir a hipótese: origem deve mudar para informação do usuário. Testar também espécie não identificada.
4. Sem conta ou com sessão anônima da IA, preencher os dados e tocar Publicar. Entrar por e-mail; repetir em outra execução com Google. Ao retornar, foto/campos devem permanecer e **nenhum registro deve ter sido publicado**. Só então tocar Publicar novamente. Repetir cancelando Google, voltando do Perfil, com erro de login e com sessão expirada.
5. Voltar do formulário editado: escolher continuar editando e conferir os dados; depois confirmar descarte. O resultado anterior, o histórico já salvo e os favoritos devem continuar iguais. Repetir após sucesso usando Concluir.
6. Publicar com conexão; abrir o avistamento confirmado e o mapa pelo botão de sucesso, verificando município e consulta atualizada. Outro usuário/visitante pode ler o publicado, mas não modificar o registro de autoria alheia.
7. Interromper conexão no envio, tocar duas vezes rapidamente e conferir o tratamento de publicação incerta/Meus registros antes de tentar um novo registro. Foto ausente/inválida ou seleção cancelada não pode gerar upload/publicação parcial. Se o Android matar o processo durante o login após gravar o checkpoint, conferir a retomada do rascunho; se um envio já tiver começado, conferir Meus registros e não repetir cegamente.
8. Conferir tela 320×480, fonte 2×, teclado e temas claro/escuro. Câmera/galeria, backend configurado e TalkBack permanecem para revisão manual em casa; acessibilidade não está totalmente validada.
