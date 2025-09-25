import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class BlockchainLedgerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> appendEntry({
    required String patientId,
    required String practitionerId,
    required String action, // create | update
    required String entryType, // vital | medication | appointment | history
    required String documentId,
    required Map<String, dynamic> payload,
  }) async {
    final col = _firestore.collection('blockchain_ledger').doc(patientId).collection('entries');

    // Fetch previous entry (highest chainIndex)
    final prevSnap = await col.orderBy('chainIndex', descending: true).limit(1).get();
    final prev = prevSnap.docs.isNotEmpty ? prevSnap.docs.first.data() : null;
    final prevHash = prev != null ? (prev['hash'] as String? ?? '') : '';
    final nextIndex = prev != null ? ((prev['chainIndex'] as int? ?? 0) + 1) : 0;

    final content = {
      'patientId': patientId,
      'practitionerId': practitionerId,
      'action': action,
      'entryType': entryType,
      'documentId': documentId,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
      'prevHash': prevHash,
      'chainIndex': nextIndex,
    };

    final jsonStr = jsonEncode(content);
    final digest = sha256.convert(utf8.encode(jsonStr)).toString();

    await col.add({
      ...content,
      'hash': digest,
    });
  }

  /// Fetch recent ledger entries for a patient, newest first.
  static Future<List<Map<String, dynamic>>> fetchEntries({
    required String patientId,
    int limit = 20,
  }) async {
    final col = _firestore.collection('blockchain_ledger').doc(patientId).collection('entries');
    final snap = await col.orderBy('chainIndex', descending: true).limit(limit).get();
    return snap.docs.map((d) => {
      'id': d.id,
      ...d.data(),
    }).toList();
  }
}
