# Assinatura da versão de release

O build de release (`flutter build apk --release` ou `flutter build appbundle`)
é assinado com a chave definida em `android/key.properties`. A chave e esse
arquivo **nunca** vão para o Git (`*.jks`, `*.keystore` e `key.properties`
estão no `.gitignore`). Sem `key.properties`, o Gradle volta a usar a chave de
debug, que serve só para testar `flutter run --release` e não para publicar.

ID do aplicativo: `br.com.ecolens`.

## 1. Gerar a chave (uma única vez)

No Windows, o `keytool` vem com o Android Studio. No PowerShell:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore "$env:USERPROFILE\ecolens-upload.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
  -alias ecolens-upload
```

O comando pede uma senha e os dados do certificado (nome, organização,
cidade). Guarde o `.jks` e a senha fora da pasta do projeto, com cópia de
segurança: sem eles não é possível publicar atualizações com a mesma
assinatura.

## 2. Criar `android/key.properties`

```properties
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_CHAVE
keyAlias=ecolens-upload
storeFile=C:/Users/SEU_USUARIO/ecolens-upload.jks
```

Use barras normais (`/`) no caminho. Confira com `git status` que o arquivo
não aparece como alteração.

## 3. Gerar a versão final

```powershell
flutter clean
flutter build apk --release
# ou, para a Play Store: flutter build appbundle --release
```

A URL do Supabase, a chave publicável e os interruptores do login com
Google e da IA já vêm ligados em `lib/core/app_config.dart`. Para apontar
para outro projeto, use `--dart-define` (por exemplo,
`--dart-define=SUPABASE_URL=...`). Só entram chaves publicáveis; nunca a
chave `service_role` nem segredos do Google.

Para conferir a assinatura do APK:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<versão>\apksigner.bat" verify --print-certs `
  build\app\outputs\flutter-apk\app-release.apk
```

O certificado exibido deve ser o `ecolens-upload`, não `Android Debug`.

## Observações

- A troca do ID de `com.example.ecolens` para `br.com.ecolens` faz o Android
  tratar o app como um novo aplicativo: desinstale a versão antiga do
  emulador ou do aparelho antes de instalar a nova.
- O login com Google usa o esquema `br.com.ecolens://auth/callback`, que já
  está registrado no Supabase e não depende do ID do app.
