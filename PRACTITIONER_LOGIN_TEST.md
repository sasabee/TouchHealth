# Practitioner Login Test Guide

## Exact Credentials to Test

### Test Account 1 - Doctor
- **Email**: `dr.smith@touchhealth.com`
- **Password**: `doctor123`
- **Expected Result**: Login as Dr. John Smith, General Practice

### Test Account 2 - Cardiologist  
- **Email**: `dr.johnson@touchhealth.com`
- **Password**: `doctor123`
- **Expected Result**: Login as Dr. Sarah Johnson, Cardiology

### Test Account 3 - Nurse
- **Email**: `nurse.williams@touchhealth.com`
- **Password**: `nurse123`
- **Expected Result**: Login as Nurse Mary Williams, Emergency Care

## Step-by-Step Testing

1. **Open the app on emulator**
2. **Look for "Healthcare Professional?" section** (blue box)
3. **Tap "Practitioner Login" button**
4. **Enter EXACTLY** one of the credential sets above
5. **Tap "Login as Practitioner"**

## Common Issues & Solutions

### If you get "Invalid login":

1. **Check for typos** - credentials are case-sensitive
2. **Make sure no extra spaces** before or after email/password
3. **Try copy-pasting** the credentials exactly as shown above
4. **Verify you're on the practitioner login screen** (not patient login)

### Debug Steps:
1. Try the first account: `dr.smith@touchhealth.com` / `doctor123`
2. If that fails, check the Flutter console for debug messages
3. The app should show debug logs with the credentials being checked

## Expected Flow After Successful Login:
1. Loading indicator appears
2. Redirects to practitioner dashboard
3. Shows welcome message with practitioner name
4. Displays quick actions for patient search
5. Shows search bar for finding patients

## If Still Having Issues:
- The authentication logic includes debug prints
- Check the Flutter console output for detailed error messages
- Verify the practitioner login screen is properly connected to the authentication cubit
