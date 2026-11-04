# Conceito 2 — etapa 1

Base visual implementada a partir das especificações fornecidas. O painel oficial
não estava disponível no ambiente. O ícone de folha preexistente foi preservado;
não é uma implementação do logotipo oficial. Solicitar os assets oficiais
(SVG/PNG e regras de aplicação) antes de incorporar o logotipo.

- Paleta: floresta `#0F3D2E`, verde `#2E7D57`, lima `#7ED957`, turquesa `#2CB5A0`.
- `AppTheme`: Material 3, Montserrat, superfícies claras/escuras, estilos globais
  de botões, campos, cartões, chips e barra de navegação.
- No tema escuro, lima assume a ação principal para manter contraste. Turquesa
  usa texto floresta; a cor de ação terciária clara é mais profunda para contraste.
- `EcoLensButton`: ações principais/tonais, ícone opcional, estado desabilitado.
- `EcoLensCard`: superfície com recorte e feedback de toque acessível.
- Integração inicial nos botões de câmera/galeria, cartões de acessos rápidos
  e campo de busca. Callbacks existentes preservados.
- A seleção Automático/Claro/Escuro e sua persistência continuam com o
  ThemeController e PreferencesService existentes, sem alterações.

Montserrat variável (normal e itálica) incluída localmente, sem chamadas de rede
em execução. Pesos 400/500/600/700 declarados no pubspec. Fonte e licença obtidas
em https://github.com/google/fonts/tree/main/ofl/montserrat (SIL OFL 1.1).

Não faz parte desta etapa: novos fluxos, redesign de telas completas, mudanças
na autenticação, controllers, serviços ou navegação.

## Validação

Executar `flutter pub get --enforce-lockfile`, `flutter analyze` e `flutter test`
com SDK compatível com o pubspec (Dart >=3.13.5; lockfile Flutter >=3.44.0).
No ambiente desta implementação, `flutter analyze` e `flutter test` foram tentados,
mas não executaram: `flutter: command not found` (código 127). O download do SDK
oficial segue bloqueado pelo proxy (HTTP 403 em storage.googleapis.com).
`git diff --check` passou. Os testes novos cobrem contraste de texto e ações,
callbacks/estado desabilitado, e seleção/persistência do tema na tela existente;
ainda precisam ser executados com Flutter disponível.
