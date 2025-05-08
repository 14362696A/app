import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SalasPage extends StatelessWidget {
  const SalasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salas')),
      drawer: AppDrawer(
  selectedIndex: 2, // índice da página Salas
  onItemSelected: (index) {
    Navigator.pop(context); // fecha o drawer

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/ensalamento');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/turmas');
        break;
      case 2:
        // já está na página Salas
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/professores');
        break;
    }
  },
),

      body: const Center(
        child: Text('Página de Salas'),
      ),
    );
  }
}
