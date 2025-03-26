plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add Firebase plugin
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wordnerd.neusenews"
    compileSdk = 35  // Updated to meet plugin requirements
    ndkVersion = "27.0.12077973"  // Updated NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Make Gradle use java 9 features
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.wordnerd.neusenews"
        minSdk = 23 // Minimum for Firebase
        // Remove or comment out the minSdkVersion line as it's redundant with minSdk
        // minSdkVersion(21) // This is the correct function syntax if you need it
        targetSdk = 35  // Updated to match compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Add the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    // Add desugar tools
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
