import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load local.properties
val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        load(FileInputStream(localPropertiesFile))
    }
}

// SDK Version Configuration with defaults
val minSdkVersion: Int = localProperties.getProperty("android.minSdk")?.toInt() ?: 26
val targetSdkVersion: Int = localProperties.getProperty("android.targetSdk")?.toInt() ?: 35
val compileSdkVersionInt: Int = localProperties.getProperty("android.compileSdk")?.toInt() ?: 35

// Validate SDK versions
require(minSdkVersion >= 26) {
    "minSdkVersion must be at least 26 for myfatoorah_flutter compatibility. Current: $minSdkVersion"
}
require(minSdkVersion <= targetSdkVersion) {
    "minSdkVersion ($minSdkVersion) cannot be greater than targetSdkVersion ($targetSdkVersion)"
}

android {
    namespace = "com.example.elite_one_mobile"
    compileSdk = compileSdkVersionInt
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.elite_one_mobile"

        // SDK versions from local.properties
        minSdk = minSdkVersion
        targetSdk = targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // MultiDex support for large apps
        multiDexEnabled = true

        // Build config fields for runtime access (if needed)
        buildConfigField("int", "MIN_SDK_VERSION", "$minSdkVersion")
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")

            // ProGuard rules for MyFatoorah (if needed)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Lint options
    lint {
        checkReleaseBuilds = true
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
}
