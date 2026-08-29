import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caloriapp_flutter/theme/theme_controller.dart';
import 'package:caloriapp_flutter/widgets/apple_theme_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppleThemeToggle alterna entre modo claro (maçã mordida) e escuro (maçã inteira)', (WidgetTester tester) async {
    ThemeController.instance.setThemeMode(ThemeMode.light);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppleThemeToggle(size: 40),
          ),
        ),
      ),
    );

    expect(ThemeController.instance.isDarkMode, isFalse);

    // Toca no botão da maçã para ativar o modo escuro
    await tester.tap(find.byType(AppleThemeToggle));
    await tester.pumpAndSettle();

    expect(ThemeController.instance.isDarkMode, isTrue);

    // Toca novamente para voltar ao modo claro (maçã mordida)
    await tester.tap(find.byType(AppleThemeToggle));
    await tester.pumpAndSettle();

    expect(ThemeController.instance.isDarkMode, isFalse);
  });
}
