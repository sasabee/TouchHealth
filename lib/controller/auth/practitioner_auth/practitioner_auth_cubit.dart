import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/model/practitioner_model.dart';

// States
abstract class PractitionerAuthState extends Equatable {
  const PractitionerAuthState();

  @override
  List<Object> get props => [];
}

class PractitionerAuthInitial extends PractitionerAuthState {}

class PractitionerAuthLoading extends PractitionerAuthState {}

class PractitionerAuthSuccess extends PractitionerAuthState {
  final PractitionerModel practitioner;

  const PractitionerAuthSuccess(this.practitioner);

  @override
  List<Object> get props => [practitioner];
}

class PractitionerAuthFailure extends PractitionerAuthState {
  final String message;

  const PractitionerAuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class PractitionerLoggedOut extends PractitionerAuthState {}

// Cubit
class PractitionerAuthCubit extends Cubit<PractitionerAuthState> {
  PractitionerAuthCubit() : super(PractitionerAuthInitial());

  PractitionerModel? _currentPractitioner;
  PractitionerModel? get currentPractitioner => _currentPractitioner;

  // Demo practitioners for testing
  final List<Map<String, String>> _demoPractitioners = [
    {
      'email': 'dr.smith@touchhealth.com',
      'password': 'doctor123',
      'name': 'Dr. John Smith',
      'licenseNumber': 'MP123456',
      'specialization': 'General Practice',
      'hospital': 'TouchHealth Medical Center',
      'department': 'General Medicine',
      'practitionerType': 'doctor',
    },
    {
      'email': 'dr.johnson@touchhealth.com',
      'password': 'doctor123',
      'name': 'Dr. Sarah Johnson',
      'licenseNumber': 'MP789012',
      'specialization': 'Cardiology',
      'hospital': 'TouchHealth Medical Center',
      'department': 'Cardiology',
      'practitionerType': 'doctor',
    },
    {
      'email': 'nurse.williams@touchhealth.com',
      'password': 'nurse123',
      'name': 'Nurse Mary Williams',
      'licenseNumber': 'RN345678',
      'specialization': 'Emergency Care',
      'hospital': 'TouchHealth Medical Center',
      'department': 'Emergency',
      'practitionerType': 'nurse',
    },
  ];

  Future<void> signIn({required String email, required String password}) async {
    emit(PractitionerAuthLoading());

    try {
      print('[Auth] signIn called with email=$email');
      // Simulate network delay
      await Future.delayed(Duration(seconds: 2));

      // Debug: Print the credentials being checked
      print('DEBUG: Attempting login with email: "$email", password: "$password"');
      
      // Check demo practitioners
      final practitionerData = _demoPractitioners.firstWhere(
        (p) {
          print('DEBUG: Checking against email: "${p['email']}", password: "${p['password']}"');
          return p['email']?.trim().toLowerCase() == email.trim().toLowerCase() && 
                 p['password'] == password;
        },
        orElse: () => {},
      );

      if (practitionerData.isEmpty) {
        print('DEBUG: No matching practitioner found');
        emit(PractitionerAuthFailure('Invalid email or password. Please check your credentials.'));
        return;
      }

      print('DEBUG: Login successful for: ${practitionerData['name']}');

      // Create practitioner model
      _currentPractitioner = PractitionerModel(
        email: practitionerData['email']!,
        uid: 'PRAC_${DateTime.now().millisecondsSinceEpoch}',
        name: practitionerData['name']!,
        phoneNumber: '+27-11-123-4567',
        licenseNumber: practitionerData['licenseNumber']!,
        specialization: practitionerData['specialization']!,
        hospital: practitionerData['hospital']!,
        department: practitionerData['department']!,
        practitionerType: practitionerData['practitionerType']!,
        isActive: true,
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        lastLogin: DateTime.now(),
      );

      // Emit success immediately so UI can navigate; log audit best-effort in background
      print('[Auth] signIn success for ${_currentPractitioner!.name}');
      emit(PractitionerAuthSuccess(_currentPractitioner!));
      // Fire-and-forget audit
      Future.microtask(() => _logLoginAudit(method: 'email').timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          ));
    } catch (e) {
      print('[Auth] signIn error: $e');
      emit(PractitionerAuthFailure('Login failed: ${e.toString()}'));
    }
  }

  // Best-effort Firestore audit for practitioner login events
  Future<void> _logLoginAudit({required String method}) async {
    try {
      final p = _currentPractitioner;
      if (p == null) return;
      await FirebaseFirestore.instance.collection('practitioner_login_audit').add({
        'uid': p.uid,
        'email': p.email,
        'licenseNumber': p.licenseNumber,
        'practitionerType': p.practitionerType,
        'method': method, // 'email' or 'hpcsa'
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // ignore
    }
  }

  // HPCSA registration number + password login path using demo data
  Future<void> signInWithHpcsa({required String hpcsaNumber, required String password}) async {
    emit(PractitionerAuthLoading());

    try {
      print('[Auth] signInWithHpcsa called with id=$hpcsaNumber');
      await Future.delayed(const Duration(milliseconds: 300));

      // Bypass matching: accept any non-empty credentials and construct a generic practitioner profile
      final id = hpcsaNumber.trim();
      if (id.isEmpty || (password.trim().isEmpty)) {
        emit(const PractitionerAuthFailure('Please enter HPCSA number and password.'));
        return;
      }

      // Infer practitioner type by prefix if possible
      String type = 'doctor';
      final upper = id.toUpperCase();
      if (upper.startsWith('RN')) type = 'nurse';
      if (upper.startsWith('PT')) type = 'physiotherapist';
      if (upper.startsWith('DP')) type = 'dentist';
      if (upper.startsWith('PS')) type = 'psychologist';

      _currentPractitioner = PractitionerModel(
        email: 'prac_${DateTime.now().millisecondsSinceEpoch}@touchhealth.local',
        uid: 'PRAC_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Demo Practitioner',
        phoneNumber: '+27-11-000-0000',
        licenseNumber: id,
        specialization: 'General',
        hospital: 'TouchHealth Medical Center',
        department: 'General',
        practitionerType: type,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastLogin: DateTime.now(),
      );

      // Emit success immediately so UI can navigate; log audit best-effort in background
      print('[Auth] signInWithHpcsa success for ${_currentPractitioner!.name}');
      emit(PractitionerAuthSuccess(_currentPractitioner!));
      // Fire-and-forget audit
      Future.microtask(() => _logLoginAudit(method: 'hpcsa').timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          ));
    } catch (e) {
      print('[Auth] signInWithHpcsa error: $e');
      emit(PractitionerAuthFailure('Login failed: ${e.toString()}'));
    }
  }

  Future<void> signOut() async {
    emit(PractitionerAuthLoading());
    
    try {
      // Simulate sign out delay
      await Future.delayed(Duration(seconds: 1));
      
      _currentPractitioner = null;
      emit(PractitionerLoggedOut());
    } catch (e) {
      emit(PractitionerAuthFailure('Sign out failed: ${e.toString()}'));
    }
  }

  bool get isAuthenticated => _currentPractitioner != null;

  void checkAuthStatus() {
    if (_currentPractitioner != null) {
      emit(PractitionerAuthSuccess(_currentPractitioner!));
    } else {
      emit(PractitionerAuthInitial());
    }
  }
}
