import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/estande.dart';

/// Leitura em tempo real dos estandes ativos.
class EstandeRepository {
  EstandeRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Estande>> ouvirAtivos() => _db
      .collection('estandes')
      .where('ativo', isEqualTo: true) // exigido pelas regras do Firestore
      .snapshots()
      .map((snap) {
        final lista =
            snap.docs.map((d) => Estande.fromMap(d.id, d.data())).toList();
        lista.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );
        return lista;
      });
}
