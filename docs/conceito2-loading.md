# EcoLens — loading com logotipo (Conceito 2)

- Widget reutilizável: `EcoLensLoadingIndicator`.
- Conteúdo de pop-up: `EcoLensLoadingDialog`.
- Ícone extraído do painel Conceito 2 fornecido no projeto; é um recorte temporário do ícone com fundo, **não substitui o asset vetorial oficial**. Quando houver SVG/PNG original, substituir o PNG sem modificar o widget.
- Animação: pulsação sutil de escala/opacidade (sem rotação), respeitando a preferência `MediaQueryData.disableAnimations`.
- Inclui rótulo semântico de status para acessibilidade.
- Este commit **não modifica fluxos de autenticação, API, identificação ou chamadas existentes**; os pop-ups da versão funcional recente ainda não estão na base publicada.

## Como integrar nos fluxos reais

1. Importe `package:ecolens/widgets/ecolens_loading_indicator.dart`.
2. Onde houver um indicador em tela, substitua somente o widget visual por `EcoLensLoadingIndicator(message: 'Identificando espécie...')`.
3. Onde houver `showDialog` de carregamento, mantenha a lógica e os controles de abertura/fechamento atuais; use `const EcoLensLoadingDialog(message: 'Carregando...')` como conteúdo. Continue encerrando o diálogo também no erro (`finally`).
4. **Não faça substituição global de todos os `CircularProgressIndicator`**: os indicadores embutidos em botões, listas ou sistemas devem ser avaliados individualmente.

## Validação pendente

Executar `flutter pub get`, `flutter analyze` e `flutter test` com SDK disponível; o ambiente desta revisão não contém Flutter. Conferir o diálogo em dispositivos pequenos, tema claro e escuro e opção de movimento reduzido.
