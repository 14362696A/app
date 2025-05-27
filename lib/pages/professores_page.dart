import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessoresPage extends StatefulWidget {
  const ProfessoresPage({super.key});

  @override
  State<ProfessoresPage> createState() => _ProfessoresPageState();
}

class _ProfessoresPageState extends State<ProfessoresPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _professoresFuture;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _materiaController = TextEditingController();
  String? _professorId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProfessores();
  }

  void _carregarProfessores() {
    setState(() => isLoading = true);
    setState(() {
      _professoresFuture = _supabase
          .from('professores')
          .select()
          .order('nome', ascending: true)
          .then((response) {
            setState(() => isLoading = false);
            if (response is List) {
              try {
                return List<Map<String, dynamic>>.from(response);
              } catch (e) {
                throw Exception('Erro ao converter dados: ${e.toString()}');
              }
            }
            throw Exception('Formato de dados inesperado');
          }).catchError((e) {
            setState(() => isLoading = false);
            throw e;
          });
    });
  }

  Future<void> _salvarProfessor() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final professor = {
        'nome': _nomeController.text,
        'email': _emailController.text,
        'telefone': _telefoneController.text.isEmpty ? null : _telefoneController.text,
        'materia': _materiaController.text,
      };

      if (_professorId == null) {
        await _supabase.from('professores').insert(professor);
      } else {
        await _supabase.from('professores')
          .update(professor)
          .eq('id', _professorId!);
      }

      _limparFormulario();
      _carregarProfessores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professor salvo com sucesso'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}'))
        );
      }
    }
  }

  void _editarProfessor(Map<String, dynamic> professor) {
    _professorId = professor['id'];
    _nomeController.text = professor['nome'];
    _emailController.text = professor['email'];
    _telefoneController.text = professor['telefone'] ?? '';
    _materiaController.text = professor['materia'];
    _abrirFormulario();
  }

  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir $nome?'),
        content: const Text('Confirma exclusão do professor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _excluirProfessor(id);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirProfessor(String id) async {
    try {
      await _supabase.from('professores').delete().eq('id', id);
      _carregarProfessores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professor excluído com sucesso'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: ${e.toString()}'))
        );
      }
    }
  }

  void _limparFormulario() {
    _professorId = null;
    _nomeController.clear();
    _emailController.clear();
    _telefoneController.clear();
    _materiaController.clear();
  }

  void _abrirFormulario() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_professorId == null ? 'Novo Professor' : 'Editar Professor'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome*'),
                  validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail*'),
                  validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                ),
                TextFormField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _materiaController,
                  decoration: const InputDecoration(labelText: 'Matéria*'),
                  validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                _salvarProfessor();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget buildListaProfessores(List<Map<String, dynamic>> lista) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lista.isEmpty) {
      return const Center(child: Text('Nenhum professor cadastrado.'));
    }

    final screenWidth = MediaQuery.of(context).size.width;

    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 1200
            ? 2
            : screenWidth < 1400
                ? 3
                : screenWidth < 1600
                    ? 4
                    : 5;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3 / 2.3,
      ),
      itemCount: lista.length,
      itemBuilder: (_, index) {
        final professor = lista[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    professor['nome'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 16, thickness: 1),
                Text('Matéria: ${professor['materia']}',
                    style: const TextStyle(fontSize: 14)),
                Text('E-mail: ${professor['email']}',
                    style: const TextStyle(fontSize: 14)),
                if (professor['telefone'] != null)
                  Text('Telefone: ${professor['telefone']}',
                      style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editarProfessor(professor),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarExclusao(
                          professor['id'], professor['nome']),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSpeedDial() {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      overlayOpacity: 0.4,
      backgroundColor: Colors.blue,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: 'Adicionar Professor',
          onTap: () {
            _limparFormulario();
            _abrirFormulario();
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.refresh),
          label: 'Atualizar',
          onTap: _carregarProfessores,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professores'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _professoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar professores',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _carregarProfessores,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final professores = snapshot.data ?? [];

          return buildListaProfessores(professores);
        },
      ),
      floatingActionButton: buildSpeedDial(),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _materiaController.dispose();
    super.dispose();
  }
}