# TouchHealth App Reinstallation Instructions

## Prerequisites
- Flutter SDK installed on your system
- Android Studio or Xcode (for iOS)
- Connected device or emulator

## Step-by-Step Reinstallation

### 1. Clean Previous Build
```bash
cd /Users/mosalefu/Touch_Health.Ai
flutter clean
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Check for Issues
```bash
flutter doctor
```

### 4. Build and Install

**For Android:**
```bash
flutter build apk --release
flutter install
```

**For iOS:**
```bash
flutter build ios --release
flutter install
```

**For Development (Debug Mode):**
```bash
flutter run
```

## New Practitioner System Features

After reinstallation, you'll have access to:

### 🩺 Practitioner Login
1. Open the app
2. Look for "Healthcare Professional?" section on login screen
3. Tap "Practitioner Login"

### 📋 Demo Accounts
- **Doctor**: `dr.smith@touchhealth.com` / `doctor123`
- **Cardiologist**: `dr.johnson@touchhealth.com` / `doctor123`
- **Nurse**: `nurse.williams@touchhealth.com` / `nurse123`

### 🔍 Patient Search
- Search by medical number: `MED000001`, `MED000002`, `MED000003`
- Search by name: "Mosa", "Sarah", "David"
- Browse all patients

## Troubleshooting

### If Build Fails:
1. Run `flutter clean`
2. Delete `pubspec.lock`
3. Run `flutter pub get`
4. Try building again

### If Dependencies Issue:
```bash
flutter pub deps
flutter pub upgrade
```

### If Platform Issues:
```bash
flutter doctor --verbose
```

## Testing the New System

1. **Test Patient Login** (existing system)
   - Email: `demo@touchhealth.com`
   - Password: `demo123`

2. **Test Practitioner Login** (new system)
   - Use any of the practitioner demo accounts above
   - Search for patients using medical numbers
   - View detailed patient records

## Files Added/Modified

The following files were added for the practitioner system:
- `lib/data/model/practitioner_model.dart`
- `lib/controller/auth/practitioner_auth/practitioner_auth_cubit.dart`
- `lib/controller/practitioner/patient_search_cubit.dart`
- `lib/core/service/patient_lookup_service.dart`
- `lib/view/screen/practitioner/practitioner_login_screen.dart`
- `lib/view/screen/practitioner/practitioner_dashboard.dart`
- `lib/view/screen/practitioner/patient_details_screen.dart`

Modified files:
- `lib/core/router/routes.dart`
- `lib/core/router/app_router.dart`
- `lib/view/screen/auth/login_screen.dart`

## Support

If you encounter any issues during installation:
1. Check Flutter doctor output
2. Ensure all dependencies are properly installed
3. Verify device/emulator is connected
4. Check the comprehensive documentation in `PRACTITIONER_SYSTEM_README.md`
