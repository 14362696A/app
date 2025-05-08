import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ProfessoresPage extends StatelessWidget {
  const ProfessoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professores')),
      drawer: AppDrawer(
  selectedIndex: 3, // índice da página Professores
  onItemSelected: (index) {
    Navigator.pop(context); // fecha o drawer

    // Redireciona para a página correta com base no índice
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/ensalamento');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/turmas');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/salas');
        break;
      case 3:
        // já está na página Professores, não faz nada
        break;
    }
  },
),

      body: const Center(
        child: Text('Página de Professores'),
      ),
    );
  }
}
