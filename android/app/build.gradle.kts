import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release: android/key.properties e o arquivo .jks ficam apenas
// na máquina de quem gera a versão final (ambos estão no .gitignore).
// Ver docs/release-signing.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "br.com.ecolens"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.ecolens"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sem key.properties (CI e testes locais), o release usa a chave de
            // debug só para permitir `flutter run --release`. A geração de
            // pacotes para publicação falha antes (ver bloco abaixo).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Sem key.properties, o pacote de release sairia assinado com a chave de
// debug. O App Bundle (usado na Play Store) para com erro; o APK só avisa,
// porque `flutter run --release` também gera um APK de release.
// No CI (variável CI=true) a regra não se aplica.
gradle.taskGraph.whenReady {
    if (keystorePropertiesFile.exists() || System.getenv("CI") == "true") {
        return@whenReady
    }
    val names = allTasks.filter { it.project == project }.map { it.name }
    if ("bundleRelease" in names) {
        throw GradleException(
            "Falta android/key.properties: o App Bundle seria assinado com a " +
                "chave de debug e recusado na Play Store. Veja docs/release-signing.md.",
        )
    }
    if ("assembleRelease" in names) {
        logger.warn(
            "AVISO: sem android/key.properties, este APK de release usa a chave " +
                "de debug e não serve para publicação.",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
