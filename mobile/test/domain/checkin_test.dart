import 'package:descobertas/domain/checkin.dart';
import 'package:descobertas/domain/estande.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRepo implements CheckinRepository {
  FakeRepo({this.estandes = const {}, this.jaExiste = false, this.falha});

  final Map<String, Estande> estandes;
  final bool jaExiste;
  final Exception? falha;
  final List<String> buscas = [];
  final List<String> registros = [];

  @override
  Future<Estande?> buscarEstande(String id) async {
    buscas.add(id);
    return estandes[id];
  }

  @override
  Future<bool> registrar(String visitanteId, String estandeId) async {
    if (falha != null) throw falha!;
    registros.add('${visitanteId}_$estandeId');
    return !jaExiste;
  }
}

const _ativo = Estande(
  id: 'e1',
  nome: 'Robô Guia',
  descricao: 'd',
  localizacao: 'A3',
  ativo: true,
);
const _inativo = Estande(
  id: 'e2',
  nome: 'Desligado',
  descricao: 'd',
  localizacao: 'B1',
  ativo: false,
);

void main() {
  test('QR inválido não consulta o repositório', () async {
    final repo = FakeRepo();
    final r = await CheckinService(repo).processar('lixo', 'u1');
    expect(r.status, CheckinStatus.qrInvalido);
    expect(r.mensagem, 'QR code inválido');
    expect(repo.buscas, isEmpty);
  });

  test('estande inexistente', () async {
    final r = await CheckinService(FakeRepo())
        .processar('circuito://estande/nada', 'u1');
    expect(r.status, CheckinStatus.naoEncontrado);
    expect(r.mensagem, 'Estande não encontrado');
  });

  test('estande inativo não grava', () async {
    final repo = FakeRepo(estandes: {'e2': _inativo});
    final r = await CheckinService(repo).processar('circuito://estande/e2', 'u1');
    expect(r.status, CheckinStatus.inativo);
    expect(r.mensagem, 'Este estande está inativo');
    expect(repo.registros, isEmpty);
  });

  test('visita já registrada', () async {
    final repo = FakeRepo(estandes: {'e1': _ativo}, jaExiste: true);
    final r = await CheckinService(repo).processar('circuito://estande/e1', 'u1');
    expect(r.status, CheckinStatus.jaRegistrado);
    expect(r.mensagem, 'Você já registrou visita neste estande');
  });

  test('sucesso grava com o id do visitante e devolve o estande', () async {
    final repo = FakeRepo(estandes: {'e1': _ativo});
    final r = await CheckinService(repo).processar(' circuito://estande/e1\n', 'u1');
    expect(r.status, CheckinStatus.sucesso);
    expect(r.estande?.id, 'e1');
    expect(r.mensagem, 'Check-in confirmado!');
    expect(repo.registros, ['u1_e1']);
  });

  test('falha de rede vira erro com o detalhe', () async {
    final repo = FakeRepo(estandes: {'e1': _ativo}, falha: Exception('offline'));
    final r = await CheckinService(repo).processar('circuito://estande/e1', 'u1');
    expect(r.status, CheckinStatus.erro);
    expect(r.mensagem, startsWith('Não foi possível registrar:'));
    expect(r.mensagem, contains('offline'));
  });
}
