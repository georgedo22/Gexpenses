plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gexpenses.app"
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
        // Unique store ID for the Play Store. The `namespace` above can stay
        // aligned with the Kotlin package, but `applicationId` must never be
        // changed again after the first release.
        applicationId = "com.gexpenses.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Keep the native libraries page-aligned inside the APK instead of having
    // the installer extract and decompress them into /data/app. Extraction
    // roughly triples the on-device footprint and needs a second copy of
    // every .so file (libflutter.so, libapp.so, plugin libraries).
    // Requires minSdk >= 23, which every current Flutter release satisfies.
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Shrink the Java/Kotlin side and strip unused resources.
            // Dart code is already tree-shaken by `flutter build --release`;
            // R8 covers the plugins' Android code (sqflite, share_plus, …).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
