import 'package:firebase_auth/firebase_auth.dart';

/// Identidade do visitante: sessão anônima do Firebase Authentication.
class AuthService {
  AuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Garante que existe um usuário (anônimo) e devolve o uid.
  Future<String> garantirLogin() async {
    final atual = _auth.currentUser;
    if (atual != null) return atual.uid;
    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }
}
