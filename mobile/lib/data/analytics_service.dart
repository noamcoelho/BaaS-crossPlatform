import 'package:firebase_analytics/firebase_analytics.dart';

/// Eventos de uso enviados ao Google Analytics para Firebase (GA4).
class AnalyticsService {
  AnalyticsService([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> missaoAberta(int qtdEstandes) => _analytics.logEvent(
        name: 'missao_aberta',
        parameters: {'qtd_estandes': qtdEstandes},
      );

  Future<void> checkinConcluido(String estandeId) => _analytics.logEvent(
        name: 'checkin_concluido',
        parameters: {'estande_id': estandeId},
      );
}
