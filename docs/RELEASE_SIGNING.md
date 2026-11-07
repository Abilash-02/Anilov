# Android Release Signing Documentation for Anilov

This guide documents the official and secure procedure for configuring release signing for the Anilov Android application.

---

## 1. Overview & Security Principles

- **Never commit keystore files (`.jks`, `.keystore`)** or keystore passwords to version control.
- Anilov uses a debug keystore for development and CI debug builds. Production release builds must be signed with a secure, private release key.
- Configuration is loaded via `android/key.properties`, which is excluded from git via `.gitignore`.

---

## 2. Generating a Release Keystore

Run the following command in a terminal (using Java keytool) to create a new upload keystore:

```bash
keytool -genkey -v \
  -keystore ~/anilov-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias anilov-release
```

During generation, you will be prompted to enter:
1. Keystore password (choose a strong password and save it securely in a password manager).
2. Key alias details (name, organization, location).

---

## 3. Configuring `key.properties`

Create a file at `android/key.properties` (never commit this file) with the following structure:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=anilov-release
storeFile=/path/to/anilov-release-key.jks
```

Ensure `.gitignore` contains:
```gitignore
# Keystores and signing properties
*.jks
*.keystore
**/android/key.properties
```

---

## 4. Gradle Configuration (`android/app/build.gradle`)

In `android/app/build.gradle` (or `build.gradle.kts`), load `key.properties` and declare the release signing config:

### Groovy (`build.gradle`):
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            // Apply release signing if key.properties is present
            if (keystorePropertiesFile.exists()) {
                signingConfig signingConfigs.release
            } else {
                signingConfig signingConfigs.debug
            }
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 5. Building Release Artifacts

### Android App Bundle (for Google Play):
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Universal Release APK:
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 6. Verifying the Signature

Verify that the generated APK is correctly signed using Android's `apksigner`:

```bash
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
```

Expected output confirms `Verified using v1 scheme (JAR signing): true` and `Verified using v2 scheme (APK Signature Scheme v2): true`.
