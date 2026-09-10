// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}
val signingPropertyNames = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val hasCompleteSigningProperties = signingPropertyNames.all { name ->
    val value = keystoreProperties.getProperty(name)?.trim().orEmpty()
    value.isNotEmpty() && value != "CHANGE_ME"
}
val releaseKeystoreFile = keystoreProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { file(it) }
val hasReleaseSigning = hasCompleteSigningProperties && releaseKeystoreFile?.isFile == true

android {
    namespace = "com.bhashakeyboard.ime"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bhashakeyboard.ime"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseKeystoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Never ship a release artifact signed with the debug keystore.
            // The task guard below produces an actionable CI/local error when
            // the upload keystore has not been configured.
            // Do not assign an incomplete signing config while Gradle is
            // configuring debug variants. The release task guard below still
            // blocks every release artifact without key.properties.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

// Debug builds remain usable for local development; release builds must have
// an explicit upload keystore and are blocked otherwise.
tasks.configureEach {
    val createsReleaseArtifact =
        (name.startsWith("assemble") || name.startsWith("bundle") || name.startsWith("package")) &&
            name.endsWith("Release")
    if (createsReleaseArtifact) {
        doFirst {
            check(hasReleaseSigning) {
                "Release signing is incomplete. Configure all values in android/key.properties and ensure storeFile points to an existing keystore."
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
}
