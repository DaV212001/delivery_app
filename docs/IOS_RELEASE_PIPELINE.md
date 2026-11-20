# AMN Delivery — iOS TestFlight CI/CD & Release Pipeline

This document details the automated iOS release architecture for **AMN Delivery** (`com.amn.delivery`), allowing developers on Windows to build, sign, and upload production `.ipa` binaries directly to **Apple TestFlight / App Store Connect** with a single command.

---

## 1. Architecture Overview

```
 ┌─────────────────────────────────────────────────────────────┐
 │                     Windows Workstation                     │
 │  dart run tool/release_ios.dart --bump=build                │
 └──────────────────────────────┬──────────────────────────────┘
                                │ 1. Git push (pubspec.yaml)
                                │ 2. Trigger gh workflow dispatch
                                ▼
 ┌─────────────────────────────────────────────────────────────┐
 │            GitHub Actions Cloud (macos-latest)              │
 │                                                             │
 │  1. Decode & Import Apple Distribution Certificate (.p12)   │
 │  2. Install AMN Delivery Provisioning Profile (.mobileprovision)
 │  3. Configure App Store Connect API Private Key (.p8)        │
 │  4. Generate dynamic ios/ExportOptions.plist                │
 │  5. Disable SwiftPM & Resolve dependencies via CocoaPods    │
 │  6. Compile, Link & Archive Release IPA                     │
 │  7. Upload to Apple TestFlight via `xcrun altool`           │
 └──────────────────────────────┬──────────────────────────────┘
                                │ 3. Apple Ingestion
                                ▼
 ┌─────────────────────────────────────────────────────────────┐
 │                Apple App Store Connect                      │
 │  • TestFlight Internal & External Testing Groups            │
 │  • Public App Store Production Review                       │
 └─────────────────────────────────────────────────────────────┘
```

---

## 2. Key Identifiers & Metadata

| Property | Value | Notes |
| :--- | :--- | :--- |
| **App Name** | AMN Delivery | Customer ordering & tracking mobile application |
| **Bundle ID** | `com.amn.delivery` | Explicit App ID registered in Apple Developer |
| **Apple Team ID** | `T6N9PJTZS6` | Natnael Chibssa (Company Team ID) |
| **Provisioning Profile Name** | `AMN Delivery` | App Store Distribution Profile |
| **Provisioning Profile UUID** | `de23b367-ac3f-4958-8427-2ab160a397b7` | Embedded in `AMN_Delivery.mobileprovision` |
| **Signing Certificate** | `Apple Distribution: Natnael Chibssa (T6N9PJTZS6)` | `.p12` distribution certificate |
| **App Store Connect Key ID**| `VQV5J6AQ78` | App Store Connect API Key |
| **App Store Connect Issuer** | `db70cb7b-56b1-4a06-b8ea-1c3fea1448dc` | Organization API Issuer ID |
| **Minimum iOS Target** | `15.0` | Configured for MapLibre vector tiles & Firebase |

---

## 3. GitHub Repository Secrets

Configure these secrets in the GitHub repository (`https://github.com/DaV212001/delivery_app/settings/secrets/actions`):

| Secret Name | Description | Example / Encoding |
| :--- | :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded `AMNCertificate.p12` | `base64 -w 0 AMNCertificate.p12` |
| `P12_PASSWORD` | Password for the `.p12` certificate file | `1234AMN@` |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded `AMN_Delivery.mobileprovision` | `base64 -w 0 AMN_Delivery.mobileprovision` |
| `KEYCHAIN_PASSWORD` | Password for temporary runner keychain | Random string (e.g. `temporary_runner_keychain_pwd_2026`) |
| `APPSTORE_API_KEY_BASE64` | Base64-encoded `AuthKey_VQV5J6AQ78.p8` | `base64 -w 0 AuthKey_VQV5J6AQ78.p8` |
| `APPSTORE_KEY_ID` | App Store Connect API Key ID | `VQV5J6AQ78` |
| `APPSTORE_ISSUER_ID` | App Store Connect Issuer ID | `db70cb7b-56b1-4a06-b8ea-1c3fea1448dc` |

---

## 4. Critical Build Engineering & Lessons Learned

### A. CocoaPods CDN vs Legacy Git Clone
* **Issue**: Declaring `source 'https://github.com/CocoaPods/Specs.git'` forces CocoaPods to clone the entire 2.5 GB git repository, consuming 12+ minutes of CI runner time and frequently timing out.
* **Resolution**: Default to CocoaPods standard CDN (`https://cdn.cocoapods.org/`), which resolves dependencies in under 4 seconds.

### B. Gebeta GL (`maplibre_gl`) Module Conflict with SwiftPM
* **Issue**: Flutter 3.29+ / 3.50+ enables experimental Swift Package Manager (SwiftPM) by default. The `gebeta_gl` plugin's `Package.swift` defines its internal target as `maplibre_gl`, but Flutter's plugin registrant generates `@import gebeta_gl;`, resulting in `Parse Issue: Module 'gebeta_gl' not found`.
* **Resolution**: Explicitly disable SwiftPM in `pubspec.yaml` and the CI workflow:
  ```yaml
  flutter:
    config:
      enable-swift-package-manager: false
  ```
  ```bash
  flutter config --no-enable-swift-package-manager
  ```
  This routes all plugins through CocoaPods where `gebeta_gl.podspec` generates a matching `gebeta_gl` Clang module.

### C. User Script Sandboxing (`ENABLE_USER_SCRIPT_SANDBOXING`)
* **Issue**: Xcode 15/16 enables user script sandboxing by default. This blocks CocoaPods' `[CP] Check Pods Manifest.lock` phase from reading `Podfile.lock`, triggering `Error: The sandbox is not in sync with the Podfile.lock`.
* **Resolution**: Set `ENABLE_USER_SCRIPT_SANDBOXING = NO` across the target build settings in `project.pbxproj` and CocoaPods' `post_install` hook:
  ```ruby
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
  ```

### D. Manual Code Signing Configuration
* **Issue**: By default, Xcode targets set `CODE_SIGN_STYLE = Automatic` and `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer"`, which fails on headless CI runners without a personal developer account signed in.
* **Resolution**:
  - `ios/Flutter/Release.xcconfig` sets `CODE_SIGN_STYLE = Manual`, `DEVELOPMENT_TEAM = T6N9PJTZS6`, `CODE_SIGN_IDENTITY = Apple Distribution`, and `PROVISIONING_PROFILE_SPECIFIER = AMN Delivery`.
  - The workflow creates a temporary keychain, sets it as the default keychain, imports the certificate with partition keys, and copies the provisioning profile by both UUID and name.

### E. Apple SDK & Toolchain Compliance
* **Current Status**: Compiled against **iOS 26.5 SDK** via **Xcode 26.6**.
* **Notice ITMS-90725**: Apple accepts builds compiled with iOS 26.5 SDK through **April 2027**. No manual intervention is needed until April 2027.

---

## 5. Releasing from Windows (CLI Guide)

From the `delivery_app` root directory on Windows:

### 1. Release with an incremented build number (Standard update)
```bash
dart run tool/release_ios.dart --bump=build
```
* Bumps build number (e.g., `1.0.19+29` $\rightarrow$ `1.0.19+30`).
* Updates `pubspec.yaml`, commits, pushes to `master`, and triggers cloud release.

### 2. Release with a patch version increment (Feature/Bugfix update)
```bash
dart run tool/release_ios.dart --bump=patch
```
* Bumps patch version (e.g., `1.0.19+29` $\rightarrow$ `1.0.20+30`).

### 3. Release with a custom version
```bash
dart run tool/release_ios.dart --version=1.1.0+35
```

### 4. Dry Run (Preview without committing or triggering CI)
```bash
dart run tool/release_ios.dart --dry-run
```

### 5. Fire and forget (Do not stream live logs in terminal)
```bash
dart run tool/release_ios.dart --bump=build --no-watch
```
You can check progress at any time with:
```bash
gh run watch
```

---

## 6. App Store Submission & Review Guidelines

1. **TestFlight Processing**:
   - Each build uploaded via `altool` takes ~5 to 15 minutes to process in [App Store Connect](https://appstoreconnect.apple.com/).
   - When asked for **Export Compliance**, select **"No"** (app uses standard HTTPS encryption).

2. **Apple Guideline 2.1 (Information Needed) Checklist**:
   - **Demo Credentials**: Provide active customer login credentials (phone number and OTP/PIN).
   - **Demonstration Video**: If requested, provide a 1–2 minute screen recording demonstrating:
     - Browsing restaurants and menus.
     - Adding items to cart.
     - Placing an order.
     - Live order tracking with map view.
     - Profile and in-app account deletion under **Profile > Delete Account** (required by App Store Guideline 5.1.1(v)).
