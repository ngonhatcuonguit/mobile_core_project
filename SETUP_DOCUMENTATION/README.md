# 📖 SETUP_DOCUMENTATION - INDEX

**Folder:** `/SETUP_DOCUMENTATION/`  
**Purpose:** Centralized setup & configuration documentation  
**Created:** 6 April 2026

---

## 📚 MAIN FILES IN THIS FOLDER

### 1. **COMPLETE_SETUP_CONFIG.md** ⭐ (START HERE!)
**Size:** ~40 KB  
**Type:** Master Configuration Guide  
**Contents:**
- Complete system setup instructions
- All required versions in one place
- Step-by-step installation
- Android & iOS configuration
- Firebase setup guide
- Build flavors (dev/prod)
- Full troubleshooting section
- Verification checklist

**Use when:** Setting up project on new Mac, or need complete reference

---

### 2. QUICK_REFERENCE.md ⚡
**Size:** ~7 KB  
**Type:** Quick Lookup Cheat Sheet  
**Contents:**
- 5-minute quick setup
- Version numbers in table format
- Quick fixes for common errors
- Common commands

**Use when:** Need to quickly look up a version or command

---

### 3. SETUP_SUMMARY.md 📄
**Size:** ~6 KB  
**Type:** 2-Page Condensed Summary  
**Contents:**
- Tool versions summary
- Quick start sequence (one command)
- Critical files checklist
- Firebase setup quick guide
- iOS/Android specific tips
- Build flavors info
- Verification commands

**Use when:** Want a printable 2-page summary

---

### 4. TROUBLESHOOTING_GUIDE.md 🔧
**Size:** ~12 KB  
**Type:** Error Fix Manual  
**Contents:**
- Flutter/Dart issues & solutions
- Android build errors (7 solutions)
- iOS build errors (5 solutions)
- Firebase issues
- Dependency problems
- Code generation issues
- General debugging tips
- Complete reset procedure

**Use when:** Build fails or app crashes

---

### 5. verify-setup.sh 🔍
**Size:** ~10 KB  
**Type:** Executable Bash Script  
**Contents:**
- Automated setup verification
- Checks all required tools
- Colored output (✅/❌/⚠️)
- Detailed diagnostics

**How to use:**
```bash
bash verify-setup.sh
```

---

## 🎯 HOW TO USE THIS FOLDER

### For First-Time Setup (New Mac)
1. Read: **COMPLETE_SETUP_CONFIG.md** (main guide)
2. Follow: Step-by-step instructions
3. Verify: Run `bash verify-setup.sh`
4. Build: `flutter run -t lib/main_dev.dart`

### For Quick Reference
→ **QUICK_REFERENCE.md** (search version/command)

### For Troubleshooting
→ **TROUBLESHOOTING_GUIDE.md** (search error)

### For Compact Version
→ **SETUP_SUMMARY.md** (2-page reference)

### For Automated Verification
```bash
cd /path/to/SETUP_DOCUMENTATION
bash verify-setup.sh
```

---

## 📋 WHAT'S COVERED IN COMPLETE_SETUP_CONFIG.MD

✅ **System Information**
- macOS version & architecture
- Flutter, Dart, Xcode versions

✅ **Required Tools** (with exact versions)
- Flutter 3.19.0
- Dart 3.3.0
- Xcode 14.1+
- Java/JDK 17+
- Android SDK API 35
- CocoaPods 1.15.2+

✅ **Installation Steps**
- Step 1-9: Complete setup guide
- Each with exact commands
- Verification for each step

✅ **Configuration Files**
- Android: build.gradle, gradle.properties
- iOS: Podfile, Xcode settings
- Project: pubspec.yaml, .env files

✅ **Firebase Setup**
- Project configuration
- Config file placement
- Feature enablement

✅ **Build Flavors**
- Dev flavor configuration
- Production flavor setup
- Build commands for each

✅ **Troubleshooting**
- 10+ common issues with solutions
- Android build fixes
- iOS build fixes
- Firebase issues

✅ **Verification Checklist**
- 10 items to verify
- Commands to run
- Expected outputs

✅ **Quick Commands Reference**
- All essential commands
- Build commands for all flavors
- Debugging commands

---

## 🚀 QUICK START

**TL;DR Version:**

```bash
# 1. Read the guide
cat COMPLETE_SETUP_CONFIG.md

# 2. Verify setup
bash verify-setup.sh

# 3. Get dependencies
flutter pub get

# 4. Run app
flutter run -t lib/main_dev.dart

# 5. Build APK (optional)
flutter build apk --flavor dev -t lib/main_dev.dart
```

---

## 📊 FILES SUMMARY TABLE

| File | Size | Type | Best For |
|------|------|------|----------|
| **COMPLETE_SETUP_CONFIG.md** | 40 KB | Master Guide | Complete setup reference |
| **QUICK_REFERENCE.md** | 7 KB | Cheat Sheet | Quick lookup |
| **SETUP_SUMMARY.md** | 6 KB | Summary | 2-page print-friendly |
| **TROUBLESHOOTING_GUIDE.md** | 12 KB | Error Manual | Fixing errors |
| **verify-setup.sh** | 10 KB | Script | Automated check |

**Total:** ~75 KB of setup documentation

---

## ✅ VERIFICATION STEPS

After setting up, run:

```bash
# Verify all tools
bash verify-setup.sh

# Check Flutter
flutter doctor -v

# Test app
flutter run -t lib/main_dev.dart
```

---

## 🎯 KEY POINTS

✅ **COMPLETE_SETUP_CONFIG.md is the authoritative source**
- Most comprehensive
- Covers all aspects
- Latest as of 6 April 2026

✅ **Other files are for quick reference**
- QUICK_REFERENCE.md for versions
- SETUP_SUMMARY.md for overview
- TROUBLESHOOTING_GUIDE.md for errors
- verify-setup.sh for validation

✅ **All versions are tested**
- Flutter 3.19.0
- Android SDK API 35
- All dependencies locked in pubspec.lock

✅ **Firebase config is critical**
- Download google-services.json (Android)
- Download GoogleService-Info.plist (iOS)
- Place in correct locations before building

---

## 📞 SUPPORT

1. Check **COMPLETE_SETUP_CONFIG.md**
2. Search **TROUBLESHOOTING_GUIDE.md**
3. Run `bash verify-setup.sh`
4. Check `flutter doctor -v`

---

## 📝 NOTES

- All files are in Markdown format (except .sh script)
- verify-setup.sh requires bash to run
- COMPLETE_SETUP_CONFIG.md is 100+ pages when printed
- All information as of 6 April 2026

---

**Navigation:** See **COMPLETE_SETUP_CONFIG.md** for detailed setup guide

Good luck! 🚀


# Upload lên Firebase App Distribution (prod)
flutter build apk --flavor prod --release --dart-define=FLAVOR=prod -t lib/main_prod.dart

# Build dev để test nội bộ
flutter build apk --flavor dev --release --dart-define=FLAVOR=dev -t lib/main_dev.dart

# Hoặc dùng script
./build-apk.sh prod release
./build-apk.sh dev release