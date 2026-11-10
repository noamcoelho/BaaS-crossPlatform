import 'package:descobertas/domain/qr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseQr', () {
    test('extrai o id de um QR válido', () {
      expect(parseQr('circuito://estande/abc'), 'abc');
    });

    test('ignora espaços e quebras de linha nas pontas', () {
      expect(parseQr(' circuito://estande/abc\n'), 'abc');
    });

    test('rejeita id vazio', () {
      expect(parseQr('circuito://estande/'), isNull);
    });

    test('rejeita id com barra', () {
      expect(parseQr('circuito://estande/a/b'), isNull);
    });

    test('rejeita conteúdo de outro formato', () {
      expect(parseQr('https://exemplo.com'), isNull);
      expect(parseQr(''), isNull);
    });
  });
}
