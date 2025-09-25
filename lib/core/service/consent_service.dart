import 'package:cloud_firestore/cloud_firestore.dart';

class ConsentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Composite key: "{medicalNumber}_{practitionerUid}"
  static String _consentDocId(String medicalNumber, String practitionerUid) =>
      '${medicalNumber}_${practitionerUid}';

  static Future<bool> hasConsent({
    required String medicalNumber,
    required String practitionerUid,
  }) async {
    try {
      final doc = await _firestore
          .collection('consents')
          .doc(_consentDocId(medicalNumber, practitionerUid))
          .get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final status = (data['status'] ?? 'revoked') as String;
      if (status != 'active') return false;
      final expiresAtIso = data['expiresAt'] as String?;
      if (expiresAtIso == null) return true;
      final expiresAt = DateTime.tryParse(expiresAtIso);
      if (expiresAt == null) return true;
      return DateTime.now().isBefore(expiresAt);
    } catch (_) {
      return false;
    }
  }

  static Future<void> grantConsent({
    required String patientUid,
    required String medicalNumber,
    required String practitionerUid,
    DateTime? expiresAt,
  }) async {
    final data = {
      'patientUid': patientUid,
      'medicalNumber': medicalNumber,
      'practitionerUid': practitionerUid,
      'status': 'active',
      'grantedAt': DateTime.now().toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
    };
    await _firestore
        .collection('consents')
        .doc(_consentDocId(medicalNumber, practitionerUid))
        .set(data, SetOptions(merge: true));
  }

  static Future<void> revokeConsent({
    required String medicalNumber,
    required String practitionerUid,
  }) async {
    await _firestore
        .collection('consents')
        .doc(_consentDocId(medicalNumber, practitionerUid))
        .set({
      'status': 'revoked',
      'revokedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // Practitioner requests access; patient must approve separately in-app
  static Future<void> requestAccess({
    required String medicalNumber,
    required String practitionerUid,
    required String practitionerName,
    required String practitionerEmail,
  }) async {
    await _firestore
        .collection('consent_requests')
        .add({
      'medicalNumber': medicalNumber,
      'practitionerUid': practitionerUid,
      'practitionerName': practitionerName,
      'practitionerEmail': practitionerEmail,
      'status': 'pending',
      'requestedAt': DateTime.now().toIso8601String(),
    });
  }
}
