import 'package:descobertas/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sem Firebase configurado mostra aviso e botão de tentar novamente',
      (tester) async {
    await tester.pumpWidget(const CircuitoApp());
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível iniciar o app'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
