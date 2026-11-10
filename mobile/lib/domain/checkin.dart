import 'estande.dart';
import 'qr.dart';

enum CheckinStatus {
  sucesso,
  qrInvalido,
  naoEncontrado,
  inativo,
  jaRegistrado,
  erro,
}

class CheckinResultado {
  const CheckinResultado(this.status, {this.estande, this.mensagemErro});

  final CheckinStatus status;
  final Estande? estande;
  final String? mensagemErro;

  String get mensagem => switch (status) {
        CheckinStatus.sucesso => 'Check-in confirmado!',
        CheckinStatus.qrInvalido => 'QR code inválido',
        CheckinStatus.naoEncontrado => 'Estande não encontrado',
        CheckinStatus.inativo => 'Este estande está inativo',
        CheckinStatus.jaRegistrado => 'Você já registrou visita neste estande',
        CheckinStatus.erro => 'Não foi possível registrar: ${mensagemErro ?? 'erro desconhecido'}',
      };
}

/// Acesso aos dados necessário para o check-in (implementado sobre o Firestore).
abstract class CheckinRepository {
  Future<Estande?> buscarEstande(String id);

  /// Grava o check-in `<visitanteId>_<estandeId>`.
  /// Retorna `false` se a visita já estava registrada.
  Future<bool> registrar(String visitanteId, String estandeId);
}

/// Valida o QR lido e registra a visita do visitante ao estande.
class CheckinService {
  CheckinService(this._repo);

  final CheckinRepository _repo;

  Future<CheckinResultado> processar(String raw, String visitanteId) async {
    final id = parseQr(raw);
    if (id == null) return const CheckinResultado(CheckinStatus.qrInvalido);
    try {
      final estande = await _repo.buscarEstande(id);
      if (estande == null) {
        return const CheckinResultado(CheckinStatus.naoEncontrado);
      }
      if (!estande.ativo) {
        return CheckinResultado(CheckinStatus.inativo, estande: estande);
      }
      final gravou = await _repo.registrar(visitanteId, id);
      return CheckinResultado(
        gravou ? CheckinStatus.sucesso : CheckinStatus.jaRegistrado,
        estande: estande,
      );
    } catch (e) {
      return CheckinResultado(CheckinStatus.erro, mensagemErro: '$e');
    }
  }
}
