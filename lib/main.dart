import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'theme/app_theme.dart'; // NOVO

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaloriApp',
      theme: appTheme, // NOVO: usa nosso tema customizado
      home: const LoginPage(),
    );
  }
}