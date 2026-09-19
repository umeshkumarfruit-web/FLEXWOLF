import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.flexwolf.flexwolf"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.flexwolf.flexwolf"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["deepLinkHost"] = (project.findProperty("FLEXWOLF_DEEP_LINK_HOST") as String?) ?: "flexwolf.com"
        manifestPlaceholders["shopifyCustomerAccountRedirectScheme"] = System.getenv("FLEXWOLF_SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_SCHEME") ?: "shop.70241911041.flexwolf"
        manifestPlaceholders["shopifyCustomerAccountRedirectHost"] = System.getenv("FLEXWOLF_SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_HOST") ?: "customer-account"
        manifestPlaceholders["shopifyCustomerAccountRedirectPath"] = System.getenv("FLEXWOLF_SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_PATH") ?: "/callback"
    }

    buildTypes {
        release {
            // Release builds omit the Dart VM/kernel and unused debug overhead.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            // Release signing is supplied locally or through CI and never committed.
            val signingFile = rootProject.file("key.properties")
            if (signingFile.exists()) {
                val properties = Properties().apply {
                    signingFile.inputStream().use(::load)
                }
                val releaseSigning = signingConfigs.create("release")
                releaseSigning.keyAlias = properties.getProperty("keyAlias")
                releaseSigning.keyPassword = properties.getProperty("keyPassword")
                releaseSigning.storeFile = properties.getProperty("storeFile")?.let(::file)
                releaseSigning.storePassword = properties.getProperty("storePassword")
                signingConfig = releaseSigning
            }
        }
    }

}

dependencies {
    implementation("com.shopify:checkout-sheet-kit:3.6.3")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
