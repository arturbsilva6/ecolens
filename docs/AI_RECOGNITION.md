# EcoLens — fase 1 do reconhecimento por IA

## Status (02/11/2026)

**Preparação de código, sem serviço ativo.** A câmera e a galeria continuam oferecendo somente o **resultado demonstrativo**. A aplicação **não executa reconhecimento real** até cumprirmos os requisitos abaixo.

Arquivos:
- Flutter: `lib/services/ai_service.dart` e `lib/models/ai_identification_result.dart`.
- Interface: `lib/screens/identification/identification_screen.dart`.
- Servidor: `supabase/functions/identify-species/index.ts`.
- Testes: `test/ai_identification_test.dart`.
- Configuração: `supabase/config.toml` com `verify_jwt = true`.

## Fluxo previsto

1. A pessoa escolhe uma foto na câmera ou galeria.
2. Ao pedir análise, uma caixa **solicita consentimento** antes do envio.
3. O app valida imagens JPEG/PNG e limita a 4 MB.
4. O app envia imagem ao endpoint autenticado da Supabase Edge Function.
5. O backend confirma **a sessão real do usuário** pelo Supabase Auth.
6. O backend encaminha a imagem ao **Google Gemini** com chave mantida somente no servidor.
7. O backend devolve uma **sugestão não verificada** ou **resultado inconclusivo**.
8. O app mostra o aviso de que não deve ser usado para verificar se animais são seguros ou perigosos.

O backend não registra fotos em tabelas ou buckets e não inclui dados de imagem em logs da função. A fotografia é enviada ao **provedor de IA** e pode conter EXIF/localização. **Ainda não implementamos remoção de metadados**; portanto, não se deve enviar fotos privadas ou com pessoas/placas/dados sensíveis. Confirmar políticas de tratamento e retenção do provedor antes de lançar.

## O que falta antes de habilitar

- [ ] Implementar **Supabase Auth** e login ou autenticação anônima controlada; o app atualmente não tem sessão de usuário.
- [ ] Adicionar limite de uso **por usuário** no servidor, monitoramento de custos e, se necessário, proteção contra abuso.
- [ ] Criar uma **chave própria Gemini** no Google AI Studio e verificar preços e cotas.
- [ ] Configurar a chave em **Supabase > Edge Functions > Secrets** sob o nome `GEMINI_API_KEY`. Não guardar em Flutter, GitHub, .env versionado ou mensagens públicas.
- [ ] Verificar disponibilidade/custo do modelo e, se necessário, definir `GEMINI_MODEL` como segredo/variável de servidor (o código usa por padrão `gemini-2.5-flash`).
- [ ] Testar localmente a função com fotos sem dados pessoais e confirmar respostas para imagem irrelevante, borrada, múltiplas espécies e espécies peçonhentas.
- [ ] Implantar `identify-species` com **verify_jwt=true**. Nunca desabilitar apenas para contornar erro 401.
- [ ] Somente após isso, habilitar o botão experimental na compilação:
  `--dart-define=ECOLENS_AI_ENABLED=true`.

**Não executar a implantação agora**: ainda não há autenticação nem cotas configuradas. A função protegida evita que uma simples chave publicável habilite uso pago irrestrito, mas autenticação sozinha não substitui a proteção contra abuso.

## Segurança científica

- A IA **não atribui percentuais de confiança confiáveis**; não exibir porcentagens inventadas.
- A IA **não define periculosidade** e não deve fornecer primeiros socorros sem revisão de fonte.
- Uma foto isolada pode ser insuficiente: retornar `identified=false` e manter o resultado inconclusivo é permitido e desejável.
- Não vincular automaticamente uma hipótese da IA a uma ficha taxonômica verificada nem indicar que a espécie foi confirmada.
- O SOS continua disponível e independente de IA, rede ou fotografia.

Fontes técnicas:
- Google Gemini, imagens: https://ai.google.dev/gemini-api/docs/image-understanding
- Supabase Edge Functions, segurança: https://supabase.com/docs/guides/functions/auth
- Supabase Edge Functions, segredos: https://supabase.com/docs/guides/functions/secrets
