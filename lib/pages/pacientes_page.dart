import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'criar_dieta_page.dart';

// Modelo simples, só pra representar o paciente por enquanto (dado fixo/mock)
class Paciente {
  final int id;
  final String nome;
  final String? fotoUrl;

  Paciente({required this.id, required this.nome, this.fotoUrl});
}

class PacientesPage extends StatelessWidget {
  const PacientesPage({super.key});

  // MOCK: lista fixa por enquanto. Depois isso vem da API (/api/pacientes/)
  static final List<Paciente> _pacientesMock = [
    Paciente(id: 1, nome: 'Ana Souza'),
    Paciente(id: 2, nome: 'Carlos Lima'),
    Paciente(id: 3, nome: 'Beatriz Alves'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pacientesMock.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final paciente = _pacientesMock[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.verdeClaro,
                backgroundImage: paciente.fotoUrl != null ? NetworkImage(paciente.fotoUrl!) : null,
                child: paciente.fotoUrl == null
                    ? Text(
                        paciente.nome[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.verdeEscuro, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(paciente.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textoSecundario),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CriarDietaPage(paciente: paciente)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}