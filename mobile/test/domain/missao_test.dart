import 'package:descobertas/domain/estande.dart';
import 'package:descobertas/domain/missao.dart';
import 'package:flutter_test/flutter_test.dart';

Estande _e(String id, {bool ativo = true}) => Estande(
      id: id,
      nome: 'Estande $id',
      descricao: 'desc',
      localizacao: 'Corredor $id',
      ativo: ativo,
    );

void main() {
  group('parseMissaoEstandes', () {
    test('separa por vírgula, remove espaços e entradas vazias', () {
      expect(parseMissaoEstandes(' a, b,,'), ['a', 'b']);
    });

    test('string vazia resulta em lista vazia', () {
      expect(parseMissaoEstandes(''), isEmpty);
      expect(parseMissaoEstandes('  ,  '), isEmpty);
    });
  });

  group('estandesDaMissao', () {
    test('mantém apenas destacados que estão na lista de ativos', () {
      final ativos = [_e('A'), _e('B')];
      expect(
        estandesDaMissao(ativos, ['B', 'X', 'C']).map((e) => e.id),
        ['B'],
      );
    });

    test('descarta estande inativo mesmo se vier na lista', () {
      final lista = [_e('A'), _e('C', ativo: false)];
      expect(estandesDaMissao(lista, ['A', 'C']).map((e) => e.id), ['A']);
    });

    test('preserva a ordem da lista de ativos', () {
      final ativos = [_e('A'), _e('B'), _e('C')];
      expect(
        estandesDaMissao(ativos, ['C', 'A']).map((e) => e.id),
        ['A', 'C'],
      );
    });

    test('sem ids destacados, missão fica vazia', () {
      expect(estandesDaMissao([_e('A')], const []), isEmpty);
    });
  });

  group('Estande.fromMap', () {
    test('campos ausentes viram vazio/false', () {
      final e = Estande.fromMap('x', const {});
      expect(e.id, 'x');
      expect(e.nome, '');
      expect(e.ativo, isFalse);
    });

    test('lê os campos do Firestore', () {
      final e = Estande.fromMap('y', const {
        'nome': 'Robô',
        'descricao': 'd',
        'localizacao': 'A3',
        'ativo': true,
      });
      expect(e.nome, 'Robô');
      expect(e.localizacao, 'A3');
      expect(e.ativo, isTrue);
    });
  });
}
