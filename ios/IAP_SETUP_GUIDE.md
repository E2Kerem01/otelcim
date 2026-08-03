# iOS In-App Purchase Setup Guide

## Overview
This guide outlines the steps required to enable In-App Purchase (IAP) functionality for the Otelcim iOS app.

## ✅ Completed Configuration

### 1. StoreKit Configuration File
- **File**: `ios/Runner/Configuration.storekit`
- **Purpose**: Local testing without App Store Connect
- **Products Configured**:
  - `boost_7_days` - 7 Günlük Öne Çıkarma (199 TL)
  - `boost_14_days` - 14 Günlük Öne Çıkarma (349 TL)
  - `boost_30_days` - 30 Günlük Öne Çıkarma (599 TL)

### 2. Info.plist Configuration
- **File**: `ios/Runner/Info.plist`
- **Changes**: Added IAP documentation comments and SKAdNetworkItems placeholder
- **Note**: No special Info.plist keys are required for basic IAP functionality

### 3. Flutter Dependencies
- `in_app_purchase: ^3.1.0` (already added to pubspec.yaml)
- `in_app_purchase_storekit: ^0.3.0` (already added to pubspec.yaml)

## 🔧 Required Manual Configuration in Xcode

### Step 1: Enable In-App Purchase Capability

1. Open the Xcode project:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. In Xcode, select the **Runner** project in the Project Navigator

3. Select the **Runner** target

4. Go to the **Signing & Capabilities** tab

5. Click the **+ Capability** button

6. Search for and add **"In-App Purchase"** capability

7. Save the project (Cmd+S)

### Step 2: Configure StoreKit Testing

1. In Xcode, with the project open, go to **Product** → **Scheme** → **Edit Scheme...**

2. Select **Run** from the left sidebar

3. Go to the **Options** tab

4. Under **StoreKit Configuration**, select `Configuration.storekit`

5. Click **Close**

This enables local testing of IAP without requiring actual App Store Connect products.

### Step 3: App Store Connect Configuration (Production)

Before releasing to production:

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)

2. Select your app (Otelcim)

3. Go to **Features** → **In-App Purchases**

4. Create the following Non-Consumable products:
   - **Product ID**: `boost_7_days`
     - **Reference Name**: 7 Day Boost
     - **Price**: 199 TL
     - **Localization (Turkish)**: 7 Günlük Öne Çıkarma
     - **Description**: İlanınızı 7 gün boyunca ana sayfada en üstte gösterir

   - **Product ID**: `boost_14_days`
     - **Reference Name**: 14 Day Boost
     - **Price**: 349 TL
     - **Localization (Turkish)**: 14 Günlük Öne Çıkarma
     - **Description**: İlanınızı 14 gün boyunca ana sayfada en üstte gösterir

   - **Product ID**: `boost_30_days`
     - **Reference Name**: 30 Day Boost
     - **Price**: 599 TL
     - **Localization (Turkish)**: 30 Günlük Öne Çıkarma
     - **Description**: İlanınızı 30 gün boyunca ana sayfada en üstte gösterir

5. Submit each product for review

## 🧪 Testing IAP

### Local Testing (StoreKit Configuration)
```bash
flutter run --debug
```
The app will use the Configuration.storekit file for testing purchases.

### Sandbox Testing (TestFlight)
1. Create sandbox test users in App Store Connect
2. Build and upload to TestFlight
3. Install via TestFlight on a test device
4. Test purchases using sandbox accounts

## 📋 Verification Checklist

- [x] StoreKit Configuration file created
- [x] Info.plist updated with IAP documentation
- [ ] In-App Purchase capability enabled in Xcode
- [ ] StoreKit Configuration selected in scheme
- [ ] Products created in App Store Connect (for production)
- [ ] Sandbox testing completed
- [ ] Receipt validation implemented (see payment_service.dart)

## 🔒 Security Notes

- Receipt validation is implemented in `lib/shared/services/payment_service.dart`
- All purchases must be verified before granting access
- Product IDs match between Configuration.storekit and App Store Connect
- Never hardcode prices - always fetch from StoreKit

## 📚 Additional Resources

- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [Flutter in_app_purchase Package](https://pub.dev/packages/in_app_purchase)
- [StoreKit Testing Documentation](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
