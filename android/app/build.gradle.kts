plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add Firebase plugin
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Import FileInputStream - add this import line
import java.io.FileInputStream

// At the top, before android block
val keystoreProperties = org.jetbrains.kotlin.konan.properties.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    // Fix the FileInputStream reference
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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

    // Add signing configuration (Kotlin DSL syntax)
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.wordnerd.neusenews"
        minSdkVersion(23)
        targetSdkVersion(34)
        versionCode = 3 // Increment this for every new release
        versionName = "1.1.0" // Update this to the new version name
    }

    buildTypes {
        release {
            // Use release signing config instead of debug
            signingConfig = signingConfigs.getByName("release")
            // Fixed Kotlin DSL syntax for proguardFiles
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Enable debug symbols
            isMinifyEnabled = true
            isShrinkResources = true
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

dependencies {
    // Add the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    // Add desugar tools
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Add AppCompat dependency for Stripe
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // Add Stripe dependencies explicitly
    implementation("com.stripe:stripe-android:20.29.1") 
}

flutter {
    source = "../.."
}
