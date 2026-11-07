# Retorno do OAuth no compartilhamento — investigação local (06/11/2026)

Repositório local: EcoLens, branch `feat/share-identification-community` (PR #15).
Sem merge, mudanças em branches de design ou Supabase remoto.

## Evidências observadas no Android

Foi usado somente o emulador já conectado (`emulator-5554`), sem abrir outro,
reinstalar o app, limpar logs/dados ou iniciar um login automaticamente. Foram
consultados PID, `logcat -b events`, `logcat -b system` e
`dumpsys activity exit-info com.example.ecolens`. URLs e parâmetros OAuth foram
removidos antes de exibir eventos; não se copiaram tokens ou campos do formulário.

O relógio do emulador está em UTC. Os eventos abaixo de 07/11/2026 correspondem
à noite de **06/11/2026 em America/Sao_Paulo**.

| UTC (07/11) | Evidência |
| --- | --- |
| 00:03:24.821 | `am_proc_died`: EcoLens PID 30557 |
| 00:03:26.251 | Novo processo EcoLens PID 8368 |
| 00:04:29.747 | `wm_on_paused_called`: EcoLens PID 8368 |
| 00:04:29.751–00:04:30.060 | Chrome iniciado/retomado |
| 00:04:31.427 | `am_proc_died`: EcoLens PID 8368 |
| 00:04:32.770 | Retorno por intenção `MAIN`, não callback `VIEW` nesse trecho |
| 00:04:32.804 | Novo processo EcoLens PID 9470 |

O histórico de encerramentos registra **reason=3 (LOW_MEMORY)** para os PIDs
30557 (RSS 486 MB) e 8368 (RSS 444 MB). Portanto, há evidência real de encerramento
por memória e recriação do processo ao sair para o Chrome. Uma reconstrução de
widgets, sozinha, não explica a troca de PID e esses registros.

**Limite da conclusão:** o trecho disponível não contém o callback Google
concluído correspondente ao relato inicial. Não se afirma que todo retorno à
Home tenha essa causa nem que o navegador tenha finalizado OAuth nesses eventos.
A reprodução solicitada ao usuário precisa ser correlacionada novamente com
PID, horário e intenção `VIEW`, com os parâmetros ocultos. O último PID consultado
durante esta investigação permaneceu 9470, sem novo callback nos eventos filtrados.

Referências: [ApplicationExitInfo](https://developer.android.com/reference/android/app/ApplicationExitInfo)
e [ciclo de vida dos processos Android](https://developer.android.com/guide/components/activities/process-lifecycle).

## Código e escopo de autenticação

- No mesmo processo, o formulário fica sob a rota única de Perfil. Os controllers
  de texto, a foto sanitizada, a origem, a data e o município pertencem ao State do
  formulário. Rebuild, pausa/retomada e conclusão/cancelamento não devem recriá-lo.
- `AccountNavigationScope` continua usando o AuthController compartilhado de
  `app.dart`, sem criar autenticação independente para compartilhar.
- `_profileNavigation` continua evitando rotas duplicadas. Sessão válida retorna
  pelo `returnLabel` do Perfil; erro/recuperação continuam no fluxo de conta.
- Antes da correção, não havia checkpoint durável. Um novo processo iniciava na
  Home mesmo que o SDK restaurasse/validasse a sessão corretamente.
- Agora o app aguarda a leitura do checkpoint antes de navegar por callback de
  erro/recuperação. Se há compartilhamento recuperado, o Perfil mantém
  **Voltar ao avistamento**. Sem rascunho, login normal e recuperação continuam
  com a navegação existente.
- O repositório de autenticação, PKCE, redirects, validação de URLs, login Google,
  recuperação de senha, logout e armazenamento de sessão do SDK não foram alterados.

## Checkpoint local do rascunho

Antes de abrir a conta, e depois da validação explícita do formulário, o app
aguarda a gravação de um único checkpoint de compartilhamento:

- foto já sanitizada (PNG, no máximo 4 MB), hipótese e origem;
- data revisada, município selecionado, lista municipal disponível e observações;
- versão e horário de criação, com validade de retomada de 24 horas.

O checkpoint usa uma chave exclusiva em SharedPreferencesAsync e **não** contém
sessão, código OAuth, token, senha, URL de callback, EXIF, GPS ou imagem do catálogo.
Não é enviado ao backend nem transforma a foto em item do histórico. A UI informa
sobre a gravação temporária. Não se introduziu dependência ou configuração remota.

Em um novo processo, o app reabre o formulário com esse snapshot, sem solicitar
novamente a IA nem depender da rede para recuperar os municípios. Também funciona
quando não há sessão ou o usuário cancelou o navegador. **Não publica ao restaurar
ou autenticar**; é necessário revisar e tocar Publicar novamente.

A cópia local é removida após voltar do Perfil no processo ativo, ao confirmar
descarte e **antes de qualquer tentativa de publicação**. Assim, um envio remoto
incerto não se converte em rascunho recuperado que incentive duplicação: permanece
a orientação de conferir Meus registros. Falha ao salvar o checkpoint impede
abrir o login; a tela e os dados continuam disponíveis para tentar novamente.

Dados expirados/incompatíveis/corrompidos são ignorados e removidos na próxima
leitura. Não há tarefa em segundo plano para apagar um registro exatamente na
hora de expiração. É um snapshot antes do login, não salvamento contínuo de cada
tecla. Limpar dados, reinstalar, expirar o prazo ou morrer antes da gravação
concluir não garante recuperação. Não há criptografia adicional nem migração do
armazenamento da sessão nesta correção.

O app declara `android:allowBackup="false"` no `AndroidManifest.xml`, para que o
rascunho com foto, o histórico local e os demais dados do app não entrem no backup
automático do Android. O atributo não cobre a transferência direta entre aparelhos
no Android 12 ou superior, que exigiria regras em `dataExtractionRules`.

## Verificação e teste no Android

Os testes diferenciam o mesmo State preservado após rebuild/lifecycle de uma
nova instância de EcoLensApp, sem as rotas/States anteriores, lendo o checkpoint
salvo. São cobertos sucesso, cancelamento, erro de callback, callback antecipado,
falha de armazenamento, expiração e publicação somente por nova ação explícita.

**Validação manual no Android concluída em 06/11/2026**, conforme relatado pelo
usuário: sucesso, cancelamento e encerramento do processo durante o login. Falha
de login e os fluxos normais do item 7 não fazem parte desse registro.

Roteiro da validação:

1. Produzir identificação real e preencher o formulário completo.
2. Anotar PID e horário, abrir Google e retornar sem enviar novamente.
3. Comparar PID, eventos de saída/início e motivo em ApplicationExitInfo.
4. Conferir foto, hipótese, origem, data, município e observações preservados.
5. Repetir cancelando e com falha de login; não publicar dados de teste.
6. Com autorização e apenas após o checkpoint, simular encerramento do app em
   segundo plano para verificar cold start. Não usar limpar dados/reinstalar.
7. Conferir login pelo Perfil, recuperação de senha e logout no fluxo normal.

Para limitar RAM no computador de 8 GB, os testes usam `--concurrency=1`, sem
build/install paralelo nem novo emulador. Não foram provocados encerramentos do
app ou do Chrome durante a reprodução do usuário.

## Resultados efetivos desta correção

- `flutter analyze --no-pub`: código 0, **No issues found**.
- `flutter test --no-pub --concurrency=1 --reporter expanded`: código 0,
  **230 testes aprovados** em aproximadamente 66 segundos (216 da base + 14 novos).
- `git diff --check`: código 0; avisos de conversão LF/CRLF são do ambiente Windows.
- Nenhuma dependência nova; nenhum build/install ou login automatizado no emulador.
- O primeiro ensaio dos testes novos de lifecycle usou uma transição inválida
  paused → resumed; a simulação foi corrigida para inactive/hidden/paused e o
  caminho inverso. Os quatro cenários dirigidos e a suíte completa passaram.
- Validação manual no Android concluída em 06/11/2026, conforme relatado pelo
  usuário: sucesso, cancelamento e encerramento do processo durante o login. A
  simulação automatizada de cold start descarta todas as rotas/States, mas não
  equivale a executar um novo processo Android; a persistência no dispositivo vem
  dessa validação manual.

Arquivos desta correção: `lib/app.dart`,
`lib/screens/community/sighting_form_screen.dart`,
`lib/models/community_share_draft.dart`,
`lib/data/share_identification_draft_store.dart`,
`test/share_identification_community_test.dart`,
`test/share_identification_draft_store_test.dart`, este guia e
`docs/share-identification-community.md`.
Os registros de plugins Linux/Windows não fazem parte desta correção.
