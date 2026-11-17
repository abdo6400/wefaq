import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun readEnvFileValue(file: java.io.File, key: String): String? {
    if (!file.exists()) return null
    for (rawLine in file.readLines()) {
        val line = rawLine.trim()
        if (line.isEmpty() || line.startsWith("#")) continue
        val eqIndex = line.indexOf('=')
        if (eqIndex <= 0) continue
        if (line.substring(0, eqIndex).trim() != key) continue
        val rawValue = line.substring(eqIndex + 1).trim()
        val value = if ((rawValue.startsWith("\"") && rawValue.endsWith("\"") && rawValue.length >= 2) ||
            (rawValue.startsWith("'") && rawValue.endsWith("'") && rawValue.length >= 2)
        ) {
            rawValue.substring(1, rawValue.length - 1)
        } else {
            rawValue
        }
        if (value.isNotEmpty()) return value
    }
    return null
}

android {
    namespace = "com.wefaq.wefaq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.wefaq.wefaq"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["wefaqLinkHost"] =
            System.getenv("WEFAQ_LINK_HOST")?.takeIf { it.isNotBlank() }
                ?: readEnvFileValue(rootProject.file("../.env"), "WEFAQ_LINK_HOST")
                ?: "unconfigured.invalid"
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
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
