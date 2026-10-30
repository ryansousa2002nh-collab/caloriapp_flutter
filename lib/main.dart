import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/botanical_background.dart';

const SystemUiOverlayStyle _whiteStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Ícones brancos no Android
  statusBarBrightness: Brightness.dark, // Ícones brancos no iOS
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(_whiteStatusBarStyle);
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
      color: const Color(0xFF7D9360),
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
          title: 'Nutri+',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeController.instance.themeMode,
          scrollBehavior: const BlueGlowScrollBehavior(),
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: _whiteStatusBarStyle,
            child: BotanicalBackground(
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true,
                child: child!,
              ),
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}
