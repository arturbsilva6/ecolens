# EcoLens — Etapa 2: redesign da Home (Conceito 2)

## Base e escopo
Branch criada a partir de `feat/auth-profile`, incluindo os fluxos funcionais
recentes de câmera, galeria, busca, favoritos, histórico, SOS e perfil.
Sem alterar controllers, Supabase, serviços, endpoints ou fluxos de autenticação.

## Implementado
- Design System Material 3 (fonte inicial Montserrat, trocada em 08/11/2026 pela fonte do sistema, Roboto, por legibilidade), cores oficiais e temas claro/escuro.
- Marca simplificada aprovada do loader incorporada como símbolo no cabeçalho.
- Hero de natureza com gradiente de alto contraste e ações de câmera/galeria.
- Layout adaptável: botões empilhados em telas estreitas ou com texto ampliado.
- Cards de acesso rápido estilizados, mantendo os cinco callbacks existentes.
- Busca textual posicionada logo após o banner principal.
- SOS fixo vermelho, SOS em card, navegação e exibição de espécies preservados.
- Loader com logo disponível como componente reutilizável; não foi conectado
  automaticamente aos fluxos (integração futura e isolada).

## Referência visual
Conceito 2, preservando a foto de sagui local como imagem provisória de banner.
A arte do painel é uma referência de direção visual, não uma especificação
literal de cada imagem ou menu. Não foram incluídas novas imagens de terceiros.

## Validação
Validação local executada com Flutter **3.47.7 stable** e Dart **3.13.5**,
compatíveis com o projeto, na branch `feat/uiux-home-conceito2` (PR #11).

| Verificação | Resultado local |
| --- | --- |
| `flutter pub get` | Dependências resolvidas, código de saída 0. |
| Formatação dos arquivos Dart alterados no PR | 11 arquivos verificados; nenhum ajuste pendente após a correção dos sete arquivos abaixo. |
| `flutter analyze` | Nenhum problema encontrado, código de saída 0. |
| `flutter test` | **169 testes aprovados**, código de saída 0. |
| `git diff --check` | Sem erros de whitespace. |

### Formatação corrigida no redesign

Somente estes sete arquivos Dart precisavam de formatação:

- `lib/core/theme/app_theme.dart`
- `lib/screens/home/home_screen.dart`
- `lib/widgets/ecolens_loading_indicator.dart`
- `lib/widgets/home/home_header.dart`
- `lib/widgets/home/identification_banner.dart`
- `lib/widgets/home/quick_access_section.dart`
- `test/home_conceito2_ui_test.dart`

O conteúdo final de cada um foi comparado com o original após `dart format`:
não há alteração de lógica. A correção do overflow do hero já publicada na
branch foi preservada. Autenticação, Supabase, identificação, favoritos,
histórico e SOS não receberam alterações nesta revisão.

### GitHub Actions

O workflow `.github/workflows/flutter-ci.yml` mantém dois jobs independentes:

- **Flutter — analyze e test:** resolve dependências e executa a análise estática
  e a suíte completa de testes, sem restringir seu escopo aos arquivos do PR.
- **Dart — formatação dos arquivos do PR:** faz checkout do head com histórico
  completo e compara os SHAs da base e do head a partir do merge-base. Verifica
  somente arquivos `.dart` adicionados, copiados, modificados ou renomeados;
  arquivos removidos não são enviados ao formatador. Nomes com espaços são
  preservados por delimitadores NUL e array Bash. Uma comparação sem arquivos
  Dart termina com sucesso, sem executar uma auditoria global por acidente.

O mesmo script Bash foi executado localmente e passou tanto na seleção dos
11 arquivos deste PR quanto em uma comparação sem arquivos alterados. Na
execução manual (`workflow_dispatch`), `base_ref` permite escolher a referência
base; o padrão é `origin/feat/auth-profile`.

A checagem global de `lib` e `test` ainda aponta **34 arquivos legados** e
retorna código 1. Essa dívida anterior ao redesign está registrada separadamente
em [formatacao-legada.md](formatacao-legada.md); os arquivos foram preservados.
Se um deles for alterado em outro PR, passará a integrar a checagem desse PR.

Para repetir as verificações no PowerShell, após buscar as referências remotas:

```powershell
flutter pub get
$arquivosDart = @(git diff --name-only --diff-filter=ACMR origin/feat/auth-profile...HEAD -- '*.dart')
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível comparar as referências.' }
if ($arquivosDart.Count -gt 0) {
  dart format --output=none --set-exit-if-changed -- $arquivosDart
}
flutter analyze
flutter test
git diff --check
```

## Validação manual restante no Android

Esta revisão não repetiu testes manuais no emulador ou aparelho. Conferir câmera,
galeria e permissões, busca, favoritos, histórico, SOS offline e discador, perfil,
navegação, teclado e aparência nos temas claro/escuro e com texto ampliado.
As validações de autenticação relatadas pelo usuário permanecem documentadas
em `docs/auth-setup.md`; testes com mocks não comprovam esses fluxos externos.

**TalkBack permanece pendente para a revisão final do aplicativo. A acessibilidade
não está totalmente validada.** Manter o PR em rascunho, sem merge, até concluir
a revisão e as verificações manuais necessárias.
