plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.roblox"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.roblox"
        // Override in android/gradle.properties before a production release.
        manifestPlaceholders["admobAppId"] = providers.gradleProperty("ADMOB_APP_ID")
            .orElse("ca-app-pub-3940256099942544~3347511713").get()
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Keep local Flutter development on the same backend as localhost:8000 in the
// browser. This task runs on every debug build (also after restarting an AVD).
// Production API_BASE_URL overrides and release builds remain independent.
val connectLocalDebugApi by tasks.registering {
    doLast {
        val executable = if (System.getProperty("os.name").startsWith("Windows")) "adb.exe" else "adb"
        val adb = android.sdkDirectory.resolve("platform-tools/$executable")
        if (adb.isFile) {
            val listing = ProcessBuilder(adb.absolutePath, "devices")
                .redirectErrorStream(true).start()
            val devices = listing.inputStream.bufferedReader().readText()
            listing.waitFor()
            devices.lineSequence().forEach { line ->
                val parts = line.trim().split(Regex("\\s+"))
                if (parts.size == 2 && parts[1] == "device") {
                    val forwarding = ProcessBuilder(adb.absolutePath, "-s", parts[0],
                        "reverse", "tcp:8000", "tcp:8000")
                        .redirectErrorStream(true).start()
                    val result = forwarding.inputStream.bufferedReader().readText().trim()
                    if (forwarding.waitFor() != 0) {
                        logger.warn("Could not connect local API for ${parts[0]}: $result")
                    } else {
                        logger.lifecycle("Local API connected for ${parts[0]} on port 8000")
                    }
                }
            }
        }
    }
}

tasks.matching { it.name == "preDebugBuild" }.configureEach {
    dependsOn(connectLocalDebugApi)
}
