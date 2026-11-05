# EcoLens — Etapa 2: redesign da Home (Conceito 2)

## Base e escopo
Branch criada a partir de `feat/auth-profile`, incluindo os fluxos funcionais
recentes de câmera, galeria, busca, favoritos, histórico, SOS e perfil.
Sem alterar controllers, Supabase, serviços, endpoints ou fluxos de autenticação.

## Implementado
- Design System Material 3 com Montserrat, cores oficiais e temas claro/escuro.
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
Os testes de widget foram adicionados, mas **não foram executados** neste
ambiente, pois Flutter/Dart não estão instalados.

Executar localmente:
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554 -t lib/main.dart
```

Conferir no emulador: câmera, galeria, busca, favoritos, histórico, SOS, perfil
e aparência; também testar tema claro, escuro e escalas de texto maiores.
Manter o PR em rascunho, sem merge, até concluir as verificações.
