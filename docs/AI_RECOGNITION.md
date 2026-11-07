# EcoLens — fase 1 do reconhecimento por IA

## Status (02/11/2026)

**Proteção de cotas no banco ativada; Edge Function ainda não implantada.** A câmera e a galeria continuam oferecendo somente o **resultado demonstrativo**. A aplicação **não executa reconhecimento real** até cumprirmos os requisitos abaixo.

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
5. Após consentimento, se necessário, o Flutter realiza **sign-in anônimo do Supabase** e o backend valida a sessão real do usuário.
6. O backend consome cota transacional protegida no PostgreSQL (**até 5 por usuário e 20 no total por dia**), antes de acessar o **Google Gemini** com chave somente no servidor.
7. O backend devolve uma **sugestão não verificada** ou **resultado inconclusivo**.
8. O app mostra o aviso de que não deve ser usado para verificar se animais são seguros ou perigosos.

O backend não registra fotos em tabelas ou buckets e não inclui dados de imagem em logs da função. A fotografia é enviada ao **provedor de IA** e pode conter EXIF/localização. **Ainda não implementamos remoção de metadados**; portanto, não se deve enviar fotos privadas ou com pessoas/placas/dados sensíveis. Confirmar políticas de tratamento e retenção do provedor antes de lançar.

## O que falta antes de habilitar

- [ ] Habilitar **Auth > Providers > Anonymous Sign-Ins** no painel para testes. O Flutter cria sessão anônima **somente após consentimento**. Para lançamento público, usar CAPTCHA/Turnstile ou autenticação comprovada para reduzir abuso.
- [x] Criado limite persistente no PostgreSQL de **5 análises/usuário/dia e 20 análises globais/dia** com RPC acessível apenas por papel administrativo. Ainda é necessária monitoração de custos e proteção contra abuso no lançamento público.
- [ ] Criar uma **chave própria Gemini** no Google AI Studio e verificar preços e cotas.
- [x] Chave nova criada e salva pelo usuário em **Supabase > Edge Functions > Secrets** sob o nome `GEMINI_API_KEY`. Nunca versionar nem compartilhar seu valor.
- [ ] Verificar disponibilidade/custo do modelo e, se necessário, definir `GEMINI_MODEL` como segredo/variável de servidor (o código usa por padrão `gemini-3.5-flash-lite`).
- [ ] Testar localmente a função com fotos sem dados pessoais e confirmar respostas para imagem irrelevante, borrada, múltiplas espécies e espécies peçonhentas.
- [ ] Implantar `identify-species` com **verify_jwt=true** depois de verificar a configuração do Auth e os testes. Nunca desabilitar apenas para contornar erro 401.
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

## Banco de dados

Migrações versionadas: `20261102052336_create_ecolens_ai_usage_quota.sql` e `20261102052441_fix_ecolens_ai_quota_coalesce.sql`. Teste transacional (com `ROLLBACK`) confirmou autorização do papel administrativo. Leitura e execução negadas para perfis públicos. Como `private.ecolens_ai_usage` não é esquema exposto, o aviso de RLS sem política é esperado: nenhum cliente deve ter acesso direto a essa tabela.
