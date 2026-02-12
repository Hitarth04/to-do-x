plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.to_do_x"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // This enables the desugaring library you added below
        isCoreLibraryDesugaringEnabled = true

        // Java 17 is compatible with modern Flutter/Android builds
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // FIX: Use simple string "17" instead of toString() calls
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID
        applicationId = "com.example.to_do_x"
        // You can update the following values to match your application needs.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // REQUIRED: MultiDex is needed for the desugaring library
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

dependencies {
    // FIX: Only include desugaring.
    // REMOVED: implementation("org.jetbrains.kotlin:kotlin-stdlib...") as it caused the error.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
