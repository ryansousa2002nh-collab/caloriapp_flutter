import 'package:flutter_test/flutter_test.dart';
import 'package:caloriapp_flutter/main.dart';

void main() {
  testWidgets('CaloriApp smoke test - carrega tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('CaloriApp'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
