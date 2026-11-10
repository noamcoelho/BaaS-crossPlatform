import 'data/analytics_service.dart';
import 'data/estande_repository.dart';
import 'data/firestore_checkin_repository.dart';
import 'data/missao_config.dart';
import 'domain/checkin.dart';

/// Dependências do app, criadas uma vez após a inicialização do Firebase.
class Servicos {
  Servicos({required this.visitanteId, required this.missao})
      : estandes = EstandeRepository(),
        checkin = CheckinService(FirestoreCheckinRepository()),
        analytics = AnalyticsService();

  final String visitanteId;
  final MissaoConfig missao;
  final EstandeRepository estandes;
  final CheckinService checkin;
  final AnalyticsService analytics;
}
