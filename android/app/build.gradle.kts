plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Upload key cho bản phát hành Google Play (spec 008, contract C2).
// File `android/key.properties` KHÔNG commit (xem .gitignore).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Package đổi từ `com.smartwardrobe.smart_wardrobe` → `online.hycat.closy`
    // (2026-09-30), đổi TRƯỚC lần publish đầu lên Play — sau khi tạo app thì
    // Google khóa package vĩnh viễn, không sửa được.
    //
    // `namespace` và `applicationId` cố tình giữ khớp nhau. `namespace` là package
    // Kotlin sinh ra R/BuildConfig nên phải khớp với `package` + đường dẫn của
    // MainActivity.kt (`kotlin/online/hycat/closy/`).
    namespace = "online.hycat.closy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Chính là giá trị phải khai trong Play Console > Package name.
        applicationId = "online.hycat.closy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Chỉ throw khi thực sự build release để không chặn build debug
            // của dev chưa có key. Bản phát hành LUÔN ký bằng upload key,
            // không fallback về debug (contract C2).
            val isReleaseTask = gradle.startParameter.taskNames.any {
                it.contains("Release", ignoreCase = true)
            }
            if (!keystorePropertiesFile.exists() && isReleaseTask) {
                throw GradleException(
                    "Missing android/key.properties — tạo theo docs/Release_Play_Checklist.md (mục 1)."
                )
            }
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
