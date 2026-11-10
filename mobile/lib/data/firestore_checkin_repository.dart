import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/checkin.dart';
import '../domain/estande.dart';

class FirestoreCheckinRepository implements CheckinRepository {
  FirestoreCheckinRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<Estande?> buscarEstande(String id) async {
    // Busca no servidor para não validar com cache desatualizado.
    final snap = await _db
        .collection('estandes')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    final data = snap.data();
    return data == null ? null : Estande.fromMap(snap.id, data);
  }

  @override
  Future<bool> registrar(String visitanteId, String estandeId) {
    final ref = _db.collection('checkins').doc('${visitanteId}_$estandeId');
    return _db.runTransaction((tx) async {
      final existente = await tx.get(ref);
      if (existente.exists) return false;
      tx.set(ref, {
        'visitanteId': visitanteId,
        'estandeId': estandeId,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}
