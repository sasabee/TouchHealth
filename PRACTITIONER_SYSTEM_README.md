# TouchHealth Practitioner System

## Overview

The TouchHealth app now includes a separate practitioner instance that allows healthcare professionals to log in and access patient information using medical numbers. This system is completely separate from the patient system and provides secure access to patient records.

## Features

### 🩺 Practitioner Authentication
- Separate login system for healthcare professionals
- Role-based access (Doctor, Nurse, etc.)
- Secure authentication with demo accounts for testing

### 🔍 Patient Search & Lookup
- Search patients by medical number (e.g., MED000001)
- Search patients by name
- Browse all available patients
- Real-time search results

### 📋 Patient Information Access
- Comprehensive patient profiles
- Medical history and allergies
- Current medications
- Vital signs and lab results
- Appointment history
- Emergency contact information

### 🛡️ Security & Access Control
- Practitioner-only access to patient data
- Session management
- Secure logout functionality

## Demo Accounts

### Practitioner Login Credentials

| Role | Email | Password | Specialization |
|------|-------|----------|----------------|
| Doctor | `dr.smith@touchhealth.com` | `doctor123` | General Practice |
| Cardiologist | `dr.johnson@touchhealth.com` | `doctor123` | Cardiology |
| Nurse | `nurse.williams@touchhealth.com` | `nurse123` | Emergency Care |

### Demo Patients Available

| Medical Number | Patient Name | Age | Gender | Blood Type |
|----------------|--------------|-----|--------|------------|
| `MED000001` or `DEMO001` | Mosa Lefu | 28 | Male | O+ |
| `MED000002` | Sarah Johnson | 35 | Female | A+ |
| `MED000003` | David Williams | 42 | Male | B+ |

## How to Use

### 1. Access Practitioner Login
1. Open the TouchHealth app
2. On the main login screen, look for the "Healthcare Professional?" section
3. Tap "Practitioner Login" button
4. You'll be redirected to the practitioner login screen

### 2. Login as Practitioner
1. Use one of the demo accounts listed above
2. Enter the email and password
3. Tap "Login as Practitioner"
4. You'll be taken to the practitioner dashboard

### 3. Search for Patients
**Method 1: Search by Medical Number**
1. On the dashboard, tap "Find Patient" quick action
2. Enter a medical number (e.g., `MED000001`)
3. Tap "Search"

**Method 2: Search by Name**
1. Use the search bar at the top
2. Type a patient name (e.g., "Mosa")
3. Results will appear automatically

**Method 3: Browse All Patients**
1. Tap "Browse Patients" quick action
2. View all available patients

### 4. View Patient Details
1. Tap on any patient from the search results
2. View comprehensive medical information including:
   - Patient demographics
   - Vital signs
   - Medical history
   - Current medications
   - Appointment history

### 5. Logout
1. Tap the menu icon (⋮) in the top-right corner
2. Select "Logout"
3. Confirm logout

## System Architecture

### New Files Created

#### Models
- `lib/data/model/practitioner_model.dart` - Practitioner user model

#### Controllers
- `lib/controller/auth/practitioner_auth/practitioner_auth_cubit.dart` - Practitioner authentication
- `lib/controller/practitioner/patient_search_cubit.dart` - Patient search functionality

#### Services
- `lib/core/service/patient_lookup_service.dart` - Patient data retrieval service

#### Views
- `lib/view/screen/practitioner/practitioner_login_screen.dart` - Practitioner login interface
- `lib/view/screen/practitioner/practitioner_dashboard.dart` - Main practitioner dashboard
- `lib/view/screen/practitioner/patient_details_screen.dart` - Patient information display

#### Routing
- Updated `lib/core/router/routes.dart` - Added practitioner routes
- Updated `lib/core/router/app_router.dart` - Added practitioner navigation
- Updated `lib/view/screen/auth/login_screen.dart` - Added practitioner access point

## Technical Details

### Authentication Flow
1. Practitioner enters credentials
2. System validates against demo accounts
3. Creates practitioner session
4. Redirects to dashboard

### Patient Data Flow
1. Practitioner searches for patient
2. System queries patient lookup service
3. Returns patient information or medical records
4. Displays in user-friendly interface

### Security Measures
- Separate authentication system from patients
- Session-based access control
- Secure logout functionality
- Role-based permissions

## Testing Instructions

### Test Scenario 1: Practitioner Login
1. Navigate to practitioner login
2. Try invalid credentials - should show error
3. Use valid demo credentials - should login successfully
4. Verify dashboard loads with practitioner information

### Test Scenario 2: Patient Search
1. Search for "MED000001" - should find Mosa Lefu
2. Search for "Sarah" - should find Sarah Johnson
3. Search for invalid medical number - should show error
4. Browse all patients - should show demo patients

### Test Scenario 3: Patient Details
1. Select a patient from search results
2. Verify all patient information loads correctly
3. Check vital signs, medical history, medications
4. Verify appointment information displays

### Test Scenario 4: System Navigation
1. Navigate between dashboard and patient details
2. Test logout functionality
3. Verify return to practitioner login after logout
4. Test switching between patient and practitioner systems

## Future Enhancements

### Potential Features
- Real database integration
- Advanced search filters
- Patient record editing capabilities
- Appointment scheduling
- Prescription management
- Multi-hospital support
- Advanced security features (2FA, etc.)

### Integration Points
- Hospital management systems
- Electronic health records (EHR)
- Pharmacy systems
- Laboratory information systems
- Imaging systems

## Troubleshooting

### Common Issues

**Login Issues**
- Ensure you're using the correct demo credentials
- Check internet connection for API calls
- Verify you're on the practitioner login screen

**Patient Search Issues**
- Medical numbers are case-sensitive
- Ensure proper format (e.g., MED000001)
- Try searching by patient name instead

**Navigation Issues**
- Use back button to return to previous screens
- Use logout to return to login screen
- Restart app if navigation becomes unresponsive

## Support

For technical support or questions about the practitioner system:
1. Check this documentation first
2. Verify you're using correct demo credentials
3. Test with known working medical numbers
4. Contact development team for additional support

---

**Note**: This is a demo system with simulated data. In a production environment, this would integrate with real healthcare databases and include additional security measures required for handling protected health information (PHI).
