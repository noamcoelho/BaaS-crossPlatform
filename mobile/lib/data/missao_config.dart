import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../domain/missao.dart';

/// Parâmetros da missão surpresa vindos do Firebase Remote Config,
/// com atualização em tempo real (sem reinstalar o app).
class MissaoConfig extends ChangeNotifier {
  MissaoConfig([FirebaseRemoteConfig? rc])
      : _rc = rc ?? FirebaseRemoteConfig.instance;

  static const chaveAtiva = 'missao_ativa';
  static const chaveEstandes = 'missao_estandes';
  static const chaveTitulo = 'missao_titulo';

  /// Padrões locais: a missão começa DESLIGADA.
  static const padroes = <String, dynamic>{
    chaveAtiva: false,
    chaveEstandes: '',
    chaveTitulo: 'Missão surpresa!',
  };

  final FirebaseRemoteConfig _rc;
  StreamSubscription<RemoteConfigUpdate>? _sub;

  bool get ativa => _rc.getBool(chaveAtiva);
  List<String> get estandeIds => parseMissaoEstandes(_rc.getString(chaveEstandes));
  String get titulo {
    final t = _rc.getString(chaveTitulo).trim();
    return t.isEmpty ? padroes[chaveTitulo] as String : t;
  }

  Future<void> iniciar() async {
    await _rc.setDefaults(padroes);
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 1),
    ));
    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config indisponível, usando padrões: $e');
    }
    _sub = _rc.onConfigUpdated.listen(
      (_) async {
        await _rc.activate();
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Falha no Remote Config em tempo real: $e'),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
