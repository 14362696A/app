import 'package:flutter/material.dart';
import 'turmas_page.dart';
import 'ensalamento_page.dart';
import 'salas_page.dart';
import 'professores_page.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    EnsalamentoPage(),
    TurmasPage(),
    SalasPage(),
    ProfessoresPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistema de Ensalamento')),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Fecha o drawer após seleção
        },
      ),
      body: _pages[_selectedIndex],
    );
  }
}
