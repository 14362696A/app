import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class TurmasPage extends StatelessWidget {
  const TurmasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turmas')),
      drawer: AppDrawer(
  selectedIndex: 1, // 1 corresponde à página "Turmas"
  onItemSelected: (index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/ensalamento');
        break;
      case 1:
        // já está na página "Turmas", não precisa fazer nada
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/salas');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/professores');
        break;
    }
  },
),

      body: const Center(
        child: Text('Página de Turmas'),
      ),
    );
  }
}
