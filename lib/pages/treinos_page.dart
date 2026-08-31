import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class TreinosPage extends StatelessWidget {
  const TreinosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 80, color: AppColors.verde),
            const SizedBox(height: 16),
            const Text(
              'Módulo de Treino em Desenvolvimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Em breve você poderá registrar e acompanhar seus treinos aqui.',
                style: TextStyle(color: AppColors.getTextoSecundario(context)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
