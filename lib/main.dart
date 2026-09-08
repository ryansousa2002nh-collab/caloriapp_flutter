import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  runApp(const MyApp());
}

class BlueGlowScrollBehavior extends ScrollBehavior {
  const BlueGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Colors.blue.shade200,
      showLeading: true,
      showTrailing: true,
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'CaloriApp',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeController.instance.themeMode,
          scrollBehavior: const BlueGlowScrollBehavior(),
          builder: (context, child) => SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: child!,
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}