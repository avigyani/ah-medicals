// Fully-qualified java.* names do NOT resolve in this Kotlin DSL script
// (Gradle reports "Unresolved reference: util/io") — import them instead.
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing from android/key.properties when present
// (CI decrypts the upload keystore into it); debug keys otherwise.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// Resolve the store file at top level: file() does not resolve inside
// the nested signingConfigs lambda ("Expression expected, but a package
// name found"). Path is relative to android/app/, as key.properties has it.
val releaseStoreFile = keystoreProperties["storeFile"]?.let { file(it as String) }

android {
    namespace = "com.dawakhata.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dawakhata.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Only create the release signing config when android/key.properties
    // exists (CI writes it after decrypting the upload keystore).
    // Creating it with empty values breaks the release build.
    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = releaseStoreFile
                storePassword = keystoreProperties["storePassword"] as String?
                storeType = keystoreProperties["storeType"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Release signing when android/key.properties exists, else debug.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
