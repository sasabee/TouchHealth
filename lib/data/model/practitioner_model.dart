class PractitionerModel {
  String email;
  String uid;
  String name;
  String phoneNumber;
  String licenseNumber;
  String specialization;
  String hospital;
  String department;
  String practitionerType; // doctor, nurse, admin, etc.
  bool isActive;
  DateTime createdAt;
  DateTime lastLogin;

  PractitionerModel({
    required this.email,
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.specialization,
    required this.hospital,
    required this.department,
    required this.practitionerType,
    this.isActive = true,
    required this.createdAt,
    required this.lastLogin,
  });

  PractitionerModel.fromJson(Map<String, dynamic> json)
      : email = json['email'] ?? '',
        uid = json['uid'] ?? '',
        name = json['name'] ?? '',
        phoneNumber = json['phoneNumber'] ?? '',
        licenseNumber = json['licenseNumber'] ?? '',
        specialization = json['specialization'] ?? '',
        hospital = json['hospital'] ?? '',
        department = json['department'] ?? '',
        practitionerType = json['practitionerType'] ?? 'doctor',
        isActive = json['isActive'] ?? true,
        createdAt = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        lastLogin = DateTime.parse(json['lastLogin'] ?? DateTime.now().toIso8601String());

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'specialization': specialization,
      'hospital': hospital,
      'department': department,
      'practitionerType': practitionerType,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  // Create a demo practitioner for testing
  static PractitionerModel createDemo() {
    return PractitionerModel(
      email: 'dr.smith@touchhealth.com',
      uid: 'PRAC001',
      name: 'Dr. John Smith',
      phoneNumber: '+27-11-123-4567',
      licenseNumber: 'MP123456',
      specialization: 'General Practice',
      hospital: 'TouchHealth Medical Center',
      department: 'General Medicine',
      practitionerType: 'doctor',
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 365)),
      lastLogin: DateTime.now(),
    );
  }
}
