import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class EnsalamentoPage extends StatelessWidget {
  const EnsalamentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ensalamento')),
      drawer: AppDrawer(
        selectedIndex: 0, // ou outro índice dependendo da página
        onItemSelected: (index) {}, // Pode deixar vazio se não quiser navegação
      ),
      body: const Center(
        child: Text('Página de Ensalamento'),
      ),
    );
  }
}
