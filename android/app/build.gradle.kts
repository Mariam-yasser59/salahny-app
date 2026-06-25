import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun dartDefineValue(name: String): String? {
    val encoded = providers.gradleProperty("dart-defines")
        .orElse(providers.environmentVariable("DART_DEFINES"))
        .orNull ?: return null

    return encoded.split(",")
        .mapNotNull { item: String ->
            try {
                String(Base64.getDecoder().decode(item))
            } catch (_: IllegalArgumentException) {
                null
            }
        }
        .firstOrNull { decoded: String -> decoded.startsWith("$name=") }
        ?.substringAfter("=")
        ?.takeIf { it.isNotBlank() }
}

android {
    namespace = "com.salahny.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.salahny.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            dartDefineValue("GOOGLE_MAPS_API_KEY")
                ?: dartDefineValue("SALAHNY_GOOGLE_MAPS_API_KEY")
                ?: providers.gradleProperty("GOOGLE_MAPS_API_KEY")
                    .orElse(providers.environmentVariable("GOOGLE_MAPS_API_KEY"))
                    .orElse("AIzaSyDU3HsRLHhXezZ8cFgN_BWpx1auMZr3Kwo")
                    .get()
    }

    buildTypes {
        debug {
            ndk {
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }
        }

        release {
            signingConfig = signingConfigs.getByName("debug")

            ndk {
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

afterEvaluate {
    tasks.matching {
        it.name.startsWith("configureCMake") || it.name.startsWith("buildCMake")
    }.configureEach {
        enabled = false
    }
}