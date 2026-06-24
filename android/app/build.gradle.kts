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
    namespace = "com.example.salahny_fixed"
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
        applicationId = "com.example.salahny_fixed"
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
            // Restrict to x86_64 only for emulator builds — prevents arm64-v8a
            // CMake from running and causing file-lock conflicts with Android Studio.
            ndk {
                abiFilters.clear()
                abiFilters.add("x86_64")
            }
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Build only arm64-v8a for physical phones — avoids parallel CMake
            // processes locking the same timing file across ABIs.
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

// This Flutter app has no native C++ sources. Flutter's Gradle plugin still
// attaches an empty CMake project to make AGP validate/download the NDK, but on
// this Windows setup that generated timing file is repeatedly locked. Disabling
// the empty CMake tasks keeps normal Flutter JNI libs and Dart AOT packaging
// intact while avoiding the no-op native configuration step.
afterEvaluate {
    tasks.matching {
        it.name.startsWith("configureCMake") || it.name.startsWith("buildCMake")
    }.configureEach {
        enabled = false
    }
}
