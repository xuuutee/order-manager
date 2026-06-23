plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.order_manager"
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
        applicationId = "com.example.order_manager"
        minSdk = 24 // Impeller requires API 24+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable Impeller Vulkan for high-performance rendering
        manifestPlaceholders += mapOf(
            "io.flutter.embedding.android.EnableImpeller" to "true"
        )
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // Code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Also test with Impeller in debug mode
            isMinifyEnabled = false
        }
    }

    // ABI split is handled by Flutter CLI: flutter build apk --split-per-abi
}

flutter {
    source = "../.."
}
