# 🎯 FLUTTER CORE PROJECT - COMPLETE SETUP & CONFIGURATION

**Generated:** 6 April 2026  
**Last Updated:** 6 April 2026  
**Project:** Flutter Core Project - My THP  
**Status:** ✅ CURRENT & COMPREHENSIVE

---

## 📚 TABLE OF CONTENTS

1. [Quick Start](#-quick-start)
2. [System Information](#-system-information)
3. [Required Tools & Versions](#-required-tools--versions)
4. [Installation Steps](#-installation-steps)
5. [Android Configuration](#-android-configuration)
6. [iOS Configuration](#-ios-configuration)
7. [Firebase Setup](#-firebase-setup)
8. [Environment Variables](#-environment-variables)
9. [Build Flavors](#-build-flavors)
10. [Project Structure](#-project-structure)
11. [Troubleshooting](#-troubleshooting)
12. [Verification Checklist](#-verification-checklist)

---

## ⚡ QUICK START

**For experienced developers (5 minutes):**

```bash
# 1. Ensure Flutter 3.19.0 is on PATH
export PATH="$HOME/development/flutter/bin:$PATH"

# 2. Clone project
git clone <repo-url> flutter_core_project && cd flutter_core_project

# 3. Clean & get dependencies
flutter clean && flutter pub get

# 4. Verify setup
flutter doctor
bash verify-setup.sh

# 5. Run dev
flutter run -t lib/main_dev.dart

# 6. Or build APK
flutter build apk --flavor dev -t lib/main_dev.dart
```

**Need detailed guide? → Read Section [Installation Steps](#-installation-steps)**

---

## 🖥️ SYSTEM INFORMATION

### Operating System
```
OS Name:              macOS Monterey
Version:              12.7.6
Build:                21H1320
Architecture:         x86_64 (Intel)
Kernel:               Darwin 21.6.0
Default Shell:        zsh
```

### Development Tools Location
```
Flutter SDK:          /Users/mac/development/flutter
Android SDK:          $HOME/Library/Android/sdk
Xcode:                /Applications/Xcode.app/Contents/Developer
Java:                 /Library/Java/JavaVirtualMachines/*/Contents/Home
```

---

## 📋 REQUIRED TOOLS & VERSIONS

### Core Flutter Development

| Tool | Version | Channel | Status |
|------|---------|---------|--------|
| **Flutter** | 3.19.0 | stable | ✅ REQUIRED |
| **Dart** | 3.3.0 | bundled | ✅ AUTO (with Flutter) |
| **Xcode** | 14.1+ | App Store | ✅ REQUIRED |
| **CocoaPods** | 1.15.2+ | RubyGems | ✅ REQUIRED |

### Android Development

| Component | Version | Status | Notes |
|-----------|---------|--------|-------|
| **Android SDK** | API 35 | ✅ REQUIRED | compileSdkVersion |
| **Target SDK** | API 35 | ✅ REQUIRED | targetSdkVersion |
| **Min SDK** | API 21 | ✅ REQUIRED | minSdkVersion |
| **Build Tools** | 35.0.0 | ✅ REQUIRED | Latest for API 35 |
| **NDK** | 27.0.12077973 | ✅ REQUIRED | For native code |
| **AGP** | 8.3.2 | ✅ REQUIRED | Android Gradle Plugin |
| **Kotlin** | 1.9.25 | ✅ REQUIRED | JVM Target: 17 |
| **Gradle** | 8.x (wrapper) | ✅ AUTO | Via gradle wrapper |

### Java/JDK

| Property | Value | Status |
|----------|-------|--------|
| **Version** | 17+ (tested: OpenJDK 25.0.2) | ✅ REQUIRED |
| **Source Compatibility** | JavaVersion.VERSION_17 | ✅ CONFIGURED |
| **Target Compatibility** | JavaVersion.VERSION_17 | ✅ CONFIGURED |
| **Core Library Desugaring** | Enabled | ✅ CONFIGURED |

### iOS Development

| Component | Version | Status |
|-----------|---------|--------|
| **Deployment Target** | iOS 17.0+ | ✅ MINIMUM |
| **Swift** | 5.7.1+ | ✅ BUNDLED (Xcode) |
| **CocoaPods** | 1.15.2+ | ✅ INSTALLED |

### Firebase & Notifications

| Package | Version | Status |
|---------|---------|--------|
| **firebase_core** | ^2.32.0 | ✅ INSTALLED |
| **firebase_messaging** | ^14.9.4 | ✅ INSTALLED |
| **firebase_analytics** | ^10.10.7 | ✅ INSTALLED |
| **firebase_crashlytics** | ^3.5.7 | ✅ INSTALLED |
| **flutter_local_notifications** | ^16.3.3 | ✅ INSTALLED |

---

## 🚀 INSTALLATION STEPS

### Step 1: Install Flutter 3.19.0

```bash
# Create development directory
mkdir -p ~/development

# Clone Flutter SDK
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Checkout exact version (if needed)
cd flutter
git checkout bae5e49bc2  # Framework revision

# Verify installation
flutter --version
# Output: Flutter 3.19.0 • channel stable • https://github.com/flutter/flutter.git
#         Framework • revision bae5e49bc2 (2 years, 2 months ago) • 2024-02-13 17:46:18 -0800
#         Engine • revision 04817c99c9
#         Tools • Dart 3.3.0 • DevTools 2.31.1
```

### Step 2: Configure Shell Environment

**File:** `~/.zshrc` (or `~/.bash_profile` for Bash)

```bash
# Add these lines to the end of the file
export PATH="$HOME/development/flutter/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/tools:$PATH"

# Java/JDK (optional, but recommended)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
# or for Java 21:
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
```

**Apply changes:**

```bash
source ~/.zshrc
```

### Step 3: Install Java/JDK

```bash
# Check if Java is installed
java -version

# If not installed, use Homebrew
brew install openjdk@21
# or
brew install openjdk@17

# Or download from Oracle
# https://jdk.java.net/ or https://www.oracle.com/java/

# Verify Java
java -version
javac -version
```

### Step 4: Install Xcode & Command Line Tools

```bash
# Xcode full installation (recommended - install from App Store)
# Or just command line tools:
xcode-select --install

# Verify
xcodebuild -version
# Expected: Xcode 14.1 or higher
```

### Step 5: Install CocoaPods

```bash
# Check if already installed
pod --version

# Install or upgrade
sudo gem install cocoapods -v 1.15.2

# Or just upgrade to latest
sudo gem install cocoapods --upgrade

# Verify
pod --version
```

### Step 6: Setup Android SDK

**Via Android Studio (Recommended):**

1. Open Android Studio
2. Go to: **Preferences/Settings** → **System Settings** → **Android SDK**
3. **SDK Platforms** tab:
   - ✅ Check "Android 15 (API 35)"
4. **SDK Tools** tab:
   - ✅ Android SDK Build Tools (35.0.0)
   - ✅ Android SDK Tools
   - ✅ Android Emulator
   - ✅ NDK (Side by side) - 27.0.12077973
5. Click "Apply" to install

**Via Command Line:**

```bash
cd ~/Library/Android/sdk/tools/bin
./sdkmanager "platforms;android-35"
./sdkmanager "build-tools;35.0.0"
./sdkmanager "ndk;27.0.12077973"
```

### Step 7: Clone & Setup Project

```bash
# Clone project
git clone <repository-url> flutter_core_project
cd flutter_core_project

# Clean build artifacts
flutter clean

# Get all dependencies (uses pubspec.lock for exact versions)
flutter pub get

# (Optional) Generate code if needed
flutter pub run build_runner build
```

### Step 8: Verify Setup

```bash
# Comprehensive diagnostics
flutter doctor -v

# Expected output: All ✓ (warnings are OK, ❌ errors must be fixed)
```

### Step 9: Download Firebase Config Files

**Android:**
1. Go to: https://console.firebase.google.com
2. Select your project
3. Project Settings → Your apps → Android app
4. Download `google-services.json`
5. Place in: `/android/app/google-services.json`

**iOS:**
1. Go to: https://console.firebase.google.com
2. Select your project
3. Project Settings → Your apps → iOS app
4. Download `GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode
6. Drag file into Runner folder
7. Check "Copy if needed"

---

## 🔧 ANDROID CONFIGURATION

### Build Configuration Files

**File:** `android/build.gradle` (Project level)

```gradle
buildscript {
    ext.kotlin_version = '1.9.25'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.2'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

**File:** `android/app/build.gradle` (App level)

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
    id "com.google.firebase.crashlytics"
}

android {
    namespace "com.digital.thp.my_thp"
    compileSdkVersion 35
    ndkVersion "27.0.12077973"

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    defaultConfig {
        applicationId "com.digital.thp.my_thp"
        minSdkVersion 21
        targetSdkVersion 35
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    flavorDimensions "environment"
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "My THP (DEV)"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "My THP"
        }
    }
}
```

**File:** `android/gradle.properties`

```gradle
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
android.suppressUnsupportedOptionWarnings=android.enableJetifier

# Set Java home if having JDK issues
# org.gradle.java.home=/path/to/jdk
```

**File:** `android/local.properties`

```properties
sdk.dir=/Users/mac/Library/Android/sdk
flutter.sdk=/Users/mac/development/flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

---

## 🍎 iOS CONFIGURATION

**File:** `ios/Podfile`

```ruby
# iOS minimum version
platform :ios, '17.0'

# CocoaPods settings
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# ... rest of file

# Build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
```

### Xcode Configuration

1. Open: `ios/Runner.xcworkspace` (NOT .xcodeproj)
2. Select "Runner" in Project Navigator
3. Go to Build Settings
4. Search "Deployment Target"
5. Set to **17.0** for all targets

### Firebase Configuration for iOS

1. Download `GoogleService-Info.plist` from Firebase Console
2. Open Xcode: `ios/Runner.xcworkspace`
3. Right-click "Runner" folder → "Add Files to Runner"
4. Select `GoogleService-Info.plist`
5. Check "Copy if needed"
6. Click "Finish"

---

## 🔥 FIREBASE SETUP

### Firebase Project Setup

1. Go to: https://console.firebase.google.com
2. Create or select project: **mythp-9b465**
3. Add Android app:
   - Package name: `com.digital.thp.my_thp` (prod) or `.dev` (dev)
   - Download `google-services.json`
4. Add iOS app:
   - Bundle ID: `com.digital.thp.mythpapp`
   - Download `GoogleService-Info.plist`

### Firebase in Code

**File:** `lib/firebase_options.dart` - Auto-generated (DO NOT EDIT MANUALLY)

**File:** `lib/main.dart` - Initialization example:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### Firebase Features

| Feature | Status | Configuration |
|---------|--------|---------------|
| **Cloud Messaging (FCM)** | ✅ Enabled | In pubspec.yaml, AndroidManifest.xml |
| **Analytics** | ✅ Enabled | Auto-enabled by default |
| **Crashlytics** | ✅ Enabled | In build.gradle files |
| **Remote Config** | ⏸️ Available | Not configured |

---

## 🌍 ENVIRONMENT VARIABLES

### Development Environment

**File:** `.env.dev`

```env
ENVIRONMENT=development
APP_TITLE=My THP (DEV)
API_BASE_URL=https://mythp-api.thp.com.vn
API_TIMEOUT_MS=30000
```

**Usage in Dart:**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

String apiUrl = dotenv.env['API_BASE_URL'] ?? '';
```

### Production Environment

**File:** `.env.prod`

```env
ENVIRONMENT=production
APP_TITLE=My THP
API_BASE_URL=https://mythp-api.thp.com.vn
API_TIMEOUT_MS=30000
```

### Shell Environment Variables

**For Flutter development (add to ~/.zshrc):**

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
export ANDROID_HOME=$HOME/Library/Android/sdk
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
```

---

## 📱 BUILD FLAVORS

### Development Flavor

```bash
# Run
flutter run -t lib/main_dev.dart

# Debug APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Release APK
flutter build apk --flavor dev -t lib/main_dev.dart --release

# Release iOS
flutter build ios --flavor dev -t lib/main_dev.dart --release
```

**Configuration:**
- App ID: `com.digital.thp.my_thp.dev`
- App Name: "My THP (DEV)"
- Version Suffix: "-dev"
- Main File: `lib/main_dev.dart`

### Production Flavor

```bash
# Run
flutter run -t lib/main_prod.dart

# Release APK
flutter build apk --flavor prod -t lib/main_prod.dart --release

# Release iOS
flutter build ios --flavor prod -t lib/main_prod.dart --release
```

**Configuration:**
- App ID: `com.digital.thp.my_thp`
- App Name: "My THP"
- Main File: `lib/main_prod.dart`

---

## 📁 PROJECT STRUCTURE

```
flutter_core_project/
│
├── lib/
│   ├── main.dart              # Main entry point
│   ├── main_dev.dart          # Dev flavor entry
│   ├── main_prod.dart         # Production entry
│   ├── firebase_options.dart  # Firebase config
│   ├── injection_container.dart # DI setup
│   │
│   ├── presentation/          # UI layer
│   │   ├── pages/             # App screens
│   │   ├── widgets/           # Reusable widgets
│   │   └── bloc/              # BLoC state management
│   │
│   ├── domain/                # Business logic
│   │   ├── entities/          # Domain models
│   │   ├── repositories/      # Abstract repos
│   │   └── usecases/          # Use cases
│   │
│   ├── data/                  # Data layer
│   │   ├── models/            # API/DB models
│   │   ├── datasources/       # APIs & DB access
│   │   ├── repositories/      # Repo implementations
│   │   └── services/          # Network services
│   │
│   ├── services/              # App services
│   │   ├── firebase_service.dart
│   │   ├── storage_service.dart
│   │   └── api_service.dart
│   │
│   ├── constants/             # Constants
│   ├── utils/                 # Utilities & helpers
│   ├── l10n/                  # Localization (vi.json, en.json)
│   ├── core/                  # Core functionality
│   └── di/                    # Dependency injection
│
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   ├── google-services.json  ⚠️ REQUIRED
│   │   └── src/
│   ├── gradle/
│   │   └── wrapper/
│   ├── build.gradle
│   ├── gradle.properties
│   ├── local.properties
│   └── settings.gradle
│
├── ios/
│   ├── Runner/
│   │   └── GoogleService-Info.plist  ⚠️ REQUIRED
│   ├── Runner.xcworkspace
│   ├── Runner.xcodeproj
│   ├── Podfile
│   └── Pods/
│
├── assets/
│   ├── images/                # PNG images
│   ├── vectors/               # SVG graphics
│   └── fonts/                 # Custom fonts (Satoshi)
│
├── pubspec.yaml               # Dependencies declaration
├── pubspec.lock              # Locked versions ✅ COMMIT
├── .env.dev                  # Dev environment
├── .env.prod                 # Prod environment
├── analysis_options.yaml     # Linting rules
└── SETUP_DOCUMENTATION/      # This folder
    └── COMPLETE_SETUP_CONFIG.md (This file)
```

---

## 🐛 TROUBLESHOOTING

### ❌ Error: "flutter: command not found"

**Fix:**

```bash
# Add to ~/.zshrc
export PATH="$HOME/development/flutter/bin:$PATH"

# Apply
source ~/.zshrc

# Verify
flutter --version
```

---

### ❌ Error: "Gradle sync failed" or "Build failed"

**Fix:**

```bash
# Deep clean
flutter clean
rm -rf .dart_tool pubspec.lock
rm -rf build/
rm -rf ~/.gradle/caches

# Rebuild
flutter pub get
flutter run -v
```

---

### ❌ Error: "CocoaPods conflict" (iOS)

**Fix:**

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

flutter clean
flutter pub get
flutter run
```

---

### ❌ Error: "Cannot resolve R" (Android)

**Fix:**

```bash
flutter clean
flutter pub get
flutter run
```

---

### ❌ Error: "Java version mismatch"

**Fix:**

```bash
# Check current Java
java -version

# If wrong, set JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 21)

# Or add to /android/gradle.properties
org.gradle.java.home=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home
```

---

### ❌ Firebase Not Working

**Check:**

```bash
# Android
ls -la android/app/google-services.json

# iOS
open ios/Runner.xcworkspace
# Check if GoogleService-Info.plist is in Runner folder
```

**If missing:**
- Download from Firebase Console
- Place in correct location
- Rebuild project

---

### ❌ Build fails with "Pods not found"

**Fix:**

```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

---

## ✅ VERIFICATION CHECKLIST

Before starting development, verify:

- [ ] **Flutter 3.19.0** installed
  ```bash
  flutter --version
  # Expected: Flutter 3.19.0
  ```

- [ ] **Dart 3.3.0** available (auto with Flutter)
  ```bash
  dart --version
  # Expected: Dart 3.3.0
  ```

- [ ] **Xcode 14.1+** installed
  ```bash
  xcodebuild -version
  # Expected: Xcode 14.1 or higher
  ```

- [ ] **Java/JDK 17+** installed
  ```bash
  java -version
  # Expected: 17 or higher
  ```

- [ ] **Android SDK API 35** installed
  - Check in Android Studio

- [ ] **CocoaPods** installed
  ```bash
  pod --version
  # Expected: 1.15.2 or higher
  ```

- [ ] **Project cloned** successfully
  ```bash
  cd flutter_core_project
  ls pubspec.yaml
  ```

- [ ] **Flutter pub get** succeeds
  ```bash
  flutter pub get
  # No errors
  ```

- [ ] **flutter doctor** passes
  ```bash
  flutter doctor
  # All ✓ (warnings OK)
  ```

- [ ] **Firebase config files** present
  ```bash
  ls android/app/google-services.json
  # File exists
  ```

- [ ] **App launches** successfully
  ```bash
  flutter run -t lib/main_dev.dart
  # App loads without errors
  ```

---

## 📊 QUICK COMMANDS REFERENCE

```bash
# Clean & fresh start
flutter clean && flutter pub get

# Run dev app
flutter run -t lib/main_dev.dart

# Run prod app
flutter run -t lib/main_prod.dart

# Build APK (dev)
flutter build apk --flavor dev -t lib/main_dev.dart

# Build APK (prod, release)
flutter build apk --flavor prod -t lib/main_prod.dart --release

# Build iOS (dev)
flutter build ios --flavor dev -t lib/main_dev.dart

# Build iOS (prod)
flutter build ios --flavor prod -t lib/main_prod.dart --release

# Check setup
flutter doctor -v

# Analyze code
flutter analyze

# Format code
dart format .

# Generate code (if needed)
flutter pub run build_runner build

# Update dependencies
flutter pub upgrade

# Check pub cache
flutter pub cache list
```

---

## 📞 GETTING HELP

1. **Check this file** for your issue
2. **Search Troubleshooting section** above
3. **Run:** `flutter doctor -v` for diagnostics
4. **Run:** `bash verify-setup.sh` for automated check
5. **Search GitHub:** flutter/flutter issues
6. **Ask on Stack Overflow:** tag `flutter`

---

## 📝 IMPORTANT REMINDERS

⚠️ **CRITICAL:**
- Download Firebase config files BEFORE running
- Place `google-services.json` in `/android/app/`
- Place `GoogleService-Info.plist` in iOS via Xcode

✅ **DO:**
- Keep `pubspec.lock` in git
- Use exact version numbers
- Run `flutter pub get` after pulling
- Test after major changes

❌ **DON'T:**
- Ignore `pubspec.lock`
- Modify it manually
- Use different versions on different machines
- Skip Firebase setup

---

## 🎉 YOU'RE READY!

Follow this guide and you'll have the project running perfectly.

**Next step:** Follow the installation steps above or run the automated setup script.

---

**Generated:** 6 April 2026  
**Last Updated:** 6 April 2026  
**Status:** ✅ COMPREHENSIVE & CURRENT

**Questions?** Check the Troubleshooting section or run `flutter doctor -v`

