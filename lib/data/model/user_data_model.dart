class UserDataModel {
  String email;
  String uid;
  String name;
  String phoneNumber;
  String dob;
  String gender;
  String bloodType;
  String saId;
  String medicalRecordNumber;
  String medicalRecordStatus;

  UserDataModel({
    required this.email,
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.dob,
    required this.gender,
    required this.bloodType,
    required this.saId,
    required this.medicalRecordNumber,
    required this.medicalRecordStatus,
  });

  UserDataModel.fromJson(Map<String, dynamic> json)
      : email = json['email'],
        uid = json['uid'],
        name = json['name'],
        phoneNumber = json['phoneNumber'],
        dob = json['dob'],
        gender = json['gender'],
        bloodType = json['bloodType'],
        saId = json['saId'] ?? '',
        medicalRecordNumber = json['medicalRecordNumber'] ?? '',
        medicalRecordStatus = json['medicalRecordStatus'] ?? 'No medical records recorded yet';

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'dob': dob,
      'gender': gender,
      'bloodType': bloodType,
      'saId': saId,
      'medicalRecordNumber': medicalRecordNumber,
      'medicalRecordStatus': medicalRecordStatus,
    };
  }
  
}
