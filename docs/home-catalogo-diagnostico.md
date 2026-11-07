# EcoLens — revisão da Home no Android (Conceito 2)

## Ajustes de interface

- Removida a borda no rodapé do `HomeHeader`.
- Na navegação inferior, removidas a sombra, elevação e tonalização. A cor agora corresponde ao fundo da Home para evitar faixa/linha marcada.
- Nenhum destino de navegação, callback, botão ou fluxo de autenticação foi alterado.

## Diagnóstico da seção “Explore as espécies”

A seção consulta `public.species` via `SupabaseSpeciesRepository.fetchPublishedSpecies()` e exibe apenas `is_published=true`. Nesta revisão foi verificado no projeto Supabase vinculado que existem **9 registros publicados**, a tabela tem as colunas consultadas, a política RLS permite leitura para `anon` e `authenticated`, e ambos possuem `SELECT`. A consulta real deve continuar (sem dados de demonstração como fallback).

Se o aplicativo não for iniciado com os parâmetros públicos `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`, `SupabaseService.requireClient()` não obtém cliente e a seção exibe erro. A causa exata no dispositivo deve ser confirmada pelo comando de inicialização e logs, não é possível inferi-la apenas pela captura.

### Como rodar com a configuração local

No PowerShell, na pasta do projeto:

```powershell
flutter run -d emulator-5554 -t lib/main.dart --dart-define-from-file=ecolens.local.json
```

Crie o arquivo **local, não versionado** `ecolens.local.json`:

```json
{
  "SUPABASE_URL": "https://SEU-PROJETO.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "SUA_CHAVE_PUBLICAVEL"
}
```

Obtenha os valores públicos do painel **Supabase > Connect** (não use `service_role`/`sb_secret`). A aplicação Flutter é pública, portanto a chave do cliente deve ser publicável; as regras RLS protegem os dados. Não cole valores no PR, prints ou logs. O arquivo `ecolens.local.json` é ignorado pelo Git.

Após alterar definições compiladas, reinicie completamente o aplicativo; hot reload não altera `String.fromEnvironment`. Se a configuração estiver correta e continuar falhando, verifique conexão do emulador, mensagens de erro no console e a disponibilidade da API (sem compartilhar tokens).

O erro agora diferencia **configuração ausente** de **falha genérica de rede**, mantendo a opção “Tentar novamente” e sem expor exceções ou credenciais.

## Testes

`flutter analyze`, `flutter test` e CI de formatação do PR devem ser verificados depois da publicação. Os testes de widget para ausência de separador e navegação foram adicionados; ainda é necessária a validação visual no Android em claro/escuro.
