# Perfil e autenticação — issue #7

Implementação destinada a Android e web. Configurações remotas não foram alteradas nem inspecionadas diretamente pelo agente; as credenciais existentes não foram lidas. O usuário validou os fluxos descritos abaixo no emulador Android, com retorno ao aplicativo. As instruções de configuração continuam como referência para outros ambientes; a integração web e as condições de produção ainda precisam de validação própria.

## Implementado no código

- Convidado é ausência de sessão, sem criação de usuário anônimo. Home, SOS, identificação, catálogo, favoritos e histórico continuam acessíveis sem conta.
- Cadastro, confirmação pendente, reenvio, login, recuperação até atualização de senha, Google OAuth e logout usam o Supabase Auth.
- O perfil guarda apenas `display_name` em `user_metadata`. É apresentação, nunca autorização. Não há tabela de perfis, migração ou alteração de RLS.
- SDK instalado e conferido: `supabase_flutter 2.18.3`, `gotrue 2.27.3`. Consultados o changelog instalado e as fontes oficiais listadas abaixo. Não houve atualização dessas versões.
- `app_links 7.2.2`, já presente como dependência transitiva do SDK, tornou-se dependência direta para receber links e apresentar erros. Não foi adicionada outra biblioteca de login Google.
- PKCE é explícito. O gerenciamento de sessão, armazenamento do verificador PKCE, restauração e refresh são do SDK. Não há persistência manual de senha/token.
- A detecção automática de links do SDK foi desativada para evitar troca duplicada. `SupabaseAuthRepository` valida o endpoint, recebe o link inicial e os links posteriores, delega `getSessionFromUrl()` ao SDK e publica somente o resultado validado. Tokens em fragmentos de URL não são importados; use os fluxos PKCE gerados pelo app.
- Android registra `br.com.ecolens://auth/callback` no Manifest e desativa o roteamento Flutter automático de deep links. O app mantém uma única rota de Perfil para callbacks de recuperação/erro. O callback Google pode atualizar a sessão sem forçar uma nova rota.
- Reenvios de confirmação têm intervalo local de 60 segundos e limite de três por cadastro pendente/instância do controlador. Limites do servidor continuam sendo a proteção efetiva; o controle local não substitui rate limiting ou proteção contra abuso.
- O reenvio usa o endereço atual do formulário, mostrado em “Destinatário da confirmação”. Editar o endereço altera o destinatário exibido, sem remover intervalo/limite nem reutilizar silenciosamente o cadastro anterior. Campo vazio/inválido desabilita o reenvio. A resposta permanece neutra sobre a existência de conta nesse endereço.
- Callbacks em andamento são bloqueados contra troca duplicada. Somente após sucesso são marcados como concluídos; um sucesso não é reprocessado durante a vida do repositório, mesmo após outro callback. Falhas temporárias de rede/timeout, HTTP 408/429 ou 5xx permitem “Tentar novamente com este link” ou reabrir o mesmo link. Apenas o link que pode ser repetido fica em memória enquanto necessário, sem persistência ou log; ele é descartado ao iniciar outra tentativa, concluir, ter erro definitivo ou descartar o repositório. Código inválido, expirado, consumido ou sem verificador PKCE exige novo link/novo login, com ação explícita na UI; não é apresentado como sucesso. Se a resposta se perder após o servidor consumir o código, uma nova tentativa pode receber esse erro definitivo e orientar novo pedido.
- Logout usa escopo local do SDK (sessão atual). Outras sessões em outros dispositivos não são encerradas. Nesta versão do SDK, a sessão local é removida antes da revogação no servidor: se a rede falhar, a UI informa que a sessão local acabou e que não foi possível confirmar a saída no servidor, sem anunciar sucesso completo. Favoritos e histórico não são apagados.

## Configuração no Supabase — referência para configuração manual

Os fluxos Android relatados pelo usuário funcionaram no ambiente utilizado. Isso não confirma, por si só, a configuração para envio público de e-mails, limites de produção ou URLs de outros ambientes.

1. Em Authentication / Providers, habilitar Email e **Confirm email**. Confirmar a política de senhas: o app valida 8–128 caracteres, mas requisitos adicionais do servidor também são aplicados e podem recusar senhas.
2. Configurar SMTP para entrega real, remetente e domínio autorizado. O serviço padrão tem restrições de destinatários e limites; não presumir envio público funcionando. Manter credenciais SMTP somente no servidor/Dashboard.
3. Revisar templates de confirmação e recuperação. Preservar o link de verificação padrão `{{ .ConfirmationURL }}`, que valida no servidor antes de redirecionar ao app. Não trocar por links com tokens expostos ao Flutter. Se customizar `redirect_to`, respeitar `{{ .RedirectTo }}` e a allowlist.
4. Em Authentication / URL Configuration:
   - **Site URL:** endereço real da aplicação web, com HTTPS em produção.
   - **Redirect URLs:** incluir exatamente `br.com.ecolens://auth/callback`.
   - Incluir cada URL web real de retorno, com porta/caminho/trailing slash correspondentes ao app. Para desenvolvimento, usar uma porta fixa do Flutter web e cadastrar a URL exata. Evitar curingas amplos em produção.
5. Revisar duração dos links e rate limits de envio/login. Verificar confirmação, reenvio, expiração e recuperação com destinatários autorizados. Confirmação de e-mail não é MFA/2FA.

## Configuração no Google — referência para configuração manual

O usuário validou o login Google no emulador Android. Conferir os passos abaixo ao configurar outro ambiente ou preparar a distribuição pública; as configurações e credenciais do console não foram inspecionadas pelo agente.

1. Criar/selecionar o projeto no Google Cloud e configurar Google Auth Platform: identidade/branding, audiência e usuários de teste enquanto o aplicativo estiver em modo de teste.
2. Criar um cliente OAuth do tipo **Web application**, pois este fluxo usa o navegador e o intermediário Supabase, inclusive no Android. Não é o fluxo nativo de ID token com SDK Google.
3. Em **Authorized redirect URIs**, cadastrar o callback HTTPS mostrado pelo provedor Google no Dashboard do Supabase (termina em `/auth/v1/callback`). Essa URI do Google é diferente do retorno final `br.com.ecolens://auth/callback` para o aplicativo.
4. Se o console pedir origens web autorizadas, cadastrar as origens reais utilizadas, sem caminho. Os redirects precisam corresponder exatamente à configuração do provedor. Usar os escopos básicos de identidade, sem adicionar permissões de Drive/Gmail.
5. Habilitar o provedor Google no Supabase e preencher Client ID e Client Secret **somente no Dashboard/servidor**. Nunca colocar Client Secret Google nem chave secret/service_role no Flutter, em dart-defines, em exemplos ou no repositório.
6. Depois de confirmar configuração e URLs, compilar com `--dart-define=AUTH_GOOGLE_ENABLED=true`. Por padrão a flag é falsa, e a UI informa que Google ainda não está habilitado; abrir o navegador não é considerado login bem-sucedido.

## Parâmetros públicos e retorno web

O app continua usando os parâmetros públicos existentes `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`. Não são exigidas novas credenciais no código. Use apenas a chave publicável do cliente; não substitua por credenciais administrativas.

- `AUTH_GOOGLE_ENABLED`: booleano público, padrão `false`; é apenas um indicador de configuração, não uma autorização.
- `AUTH_WEB_REDIRECT_URL`: URL pública e absoluta de retorno à aplicação web, sem query/fragment. Se omitida, usa origem e caminho atuais, removendo query/fragment. Precisa estar na allowlist Supabase. Usar a URL que serve o app, normalmente a raiz, evitando rota web inexistente. Hospedagem deve entregar o Flutter nessa URL.
- Para Android, o retorno é a constante `br.com.ecolens://auth/callback`. Não há Client Secret no aplicativo. O manifest não configura callbacks de iOS/desktop; esses retornos estão fora desta entrega e a UI informa a limitação ao iniciar fluxos com redirect nessas plataformas.

PKCE exige que confirmação, recuperação e OAuth sejam concluídos no mesmo navegador/instalação que iniciou a operação. Um link aberto em outro dispositivo, com storage limpo ou após substituir o verificador pode falhar: solicitar um novo link no dispositivo de destino. Iniciar vários fluxos ao mesmo tempo pode invalidar o fluxo anterior.

O código de retorno é de uso único e não é logado pelo aplicativo. Não compartilhar URLs de callback, capturas com códigos, senhas ou sessões. HTTPS é necessário na web de produção; custom schemes Android dependem do sistema para entregar o link. Para distribuição pública, avaliar App Links verificados com domínio próprio.

## Testes automatizados

Os testes usam repositório injetado ou SDK real com HTTP, armazenamento PKCE e fontes de links simulados. Verificam cadastro pendente, sessão restaurada, login, logout com falha, edição de nome, pedido neutro de recuperação, troca PKCE e atualização de senha, callback expirado/cancelado, descarte, duplicação de rota e preservação dos dados locais. Também exercitam telas em 320×480 com texto 2×, temas claro/escuro e campos de senha ocultáveis. Isso não comprova entrega de e-mail, configuração Google ou retorno real do sistema operacional.

### Resultado da revisão automatizada — 05/11/2026

Comandos executados pelo agente na branch `feat/auth-profile`, usando as dependências já resolvidas:

| Comando | Resultado obtido |
| --- | --- |
| `flutter analyze --no-pub` | Concluído com código de saída 0; nenhum problema encontrado. |
| `flutter test --no-pub` | Concluído com código de saída 0; 165 testes passaram na suíte completa. |
| `git diff --check` | Concluído com código de saída 0; nenhum erro de whitespace. |

Os arquivos novos ainda não rastreados também foram verificados separadamente com `git diff --no-index --check`. A suíte completa inclui os testes existentes de inicialização, Home, SOS, catálogo, favoritos, histórico e identificação, além dos testes de autenticação e Perfil. Esta revisão atualizou somente este documento e preservou as alterações de implementação já presentes no workspace, sem adicionar credenciais ou arquivos de configuração local.

## Validação manual realizada pelo usuário — emulador Android

Registro de 05/11/2026, na branch `feat/auth-profile`. Os resultados abaixo foram relatados pelo usuário após execução manual no emulador Android:

| Fluxo | Resultado informado pelo usuário |
| --- | --- |
| Cadastro e confirmação por e-mail | Validado, incluindo retorno ao aplicativo após a confirmação. |
| Login por e-mail | Validado, incluindo persistência da sessão após fechar e reabrir o aplicativo. |
| Logout | Validado. |
| Recuperação de senha | Validados o fluxo de recuperação, a rejeição da senha atual ao tentar reutilizá-la e o login com a nova senha. |
| Login com Google | Validado, incluindo retorno ao aplicativo e exibição da conta no Perfil. |

Esses resultados foram informados pelo usuário e não representam uma execução manual feita pelo agente. Não foram registrados e-mails de contas, senhas, tokens, links de uso único ou credenciais de configuração.

## Validação manual restante

A validação manual com **TalkBack foi adiada para a revisão final do aplicativo** e permanece pendente. A acessibilidade **não está totalmente validada**: os testes automatizados de layout e os controles implementados não substituem a avaliação com leitor de tela em dispositivo. O relato dos fluxos funcionais acima não encerra essa pendência.

Além dos fluxos Android já relatados acima, ainda precisam de validação manual específica:

- Abrir Home e SOS sem conta, inclusive offline. Usar identificação, busca, catálogo, favoritos, histórico e configurações.
- Testar reenvio de confirmação, inclusive cadastro A → edição para B, intervalo/limite e links expirados ou reutilizados.
- Testar senha incorreta, conta ainda não confirmada, indisponibilidade e limite de tentativas no login.
- Verificar os callbacks de confirmação e recuperação com o app fechado e aberto, links inválidos/expirados/consumidos e nova tentativa após falha transitória. O relato de retorno ao app não distingue todas essas condições.
- Cancelar Google no navegador e voltar sem sessão falsa; distinguir retorno com app fechado e aberto.
- Editar nome; testar refresh da sessão e logout sem rede. Reabrir favoritos/histórico e verificar que continuam locais.
- Exercitar teclado, senhas ocultáveis e texto ampliado em dispositivo; realizar a revisão com TalkBack na etapa final indicada acima.
- Executar os fluxos completos na web, incluindo configuração das URLs de retorno. A validação Android não comprova a integração web.

Antes da disponibilização pública, planejar exclusão da conta e ciclo de eliminação de dados (revogação de sessões, retenção de dados Auth, exclusão no provedor quando aplicável e explicação sobre dados locais). Não há remoção de conta nesta entrega. SMS, MFA/2FA, comunidade, mapas, avatar, alteração de e-mail e sincronização estão fora do escopo.

## Referências oficiais consultadas

- [Supabase Flutter changelog](https://github.com/supabase/supabase-flutter/blob/main/packages/supabase_flutter/CHANGELOG.md)
- [Password-based Auth](https://supabase.com/docs/guides/auth/passwords)
- [resetPasswordForEmail e atualização de senha](https://supabase.com/docs/reference/dart/auth-resetpasswordforemail)
- [Eventos e descarte da subscription](https://supabase.com/docs/reference/dart/auth-onauthstatechange)
- [OAuth no Flutter](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
- [Reenvio de confirmação](https://supabase.com/docs/reference/dart/auth-resend)
- [Mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
- [Google via Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-google)
- [Google OAuth e correspondência dos redirects](https://developers.google.com/identity/protocols/oauth2/web-server)
- [SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
