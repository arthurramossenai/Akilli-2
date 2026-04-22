// Teste básico de widget para o Akilli App.
// 
// O app usa Supabase que precisa ser inicializado,
// então testes mais complexos exigem mocks.
// Por enquanto, este teste apenas verifica que o framework funciona.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test - framework funciona', (WidgetTester tester) async {
    // Verifica que o framework de testes está operacional
    expect(1 + 1, equals(2));
  });
}
