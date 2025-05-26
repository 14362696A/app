import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _carregarProfessores();
  }

  void _carregarProfessores() {
    setState(() {
      _professoresFuture = _supabase
          .from('professores')
          .select()
          .order('nome', ascending: true)
          .then((response) {
            if (response is List) {
              try {
                return List<Map<String, dynamic>>.from(response);
              } catch (e) {
                throw Exception('Erro ao converter dados: ${e.toString()}');
              }
            }
            throw Exception('Formato de dados inesperado');
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

  Future<void> _excluirProfessor(String id) async {
    try {
      await _supabase.from('professores').delete().eq('id', id);
      _carregarProfessores();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professores')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _professoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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

          final professores = snapshot.data!;

          if (professores.isEmpty) {
            return const Center(
              child: Text('Nenhum professor cadastrado'),
            );
          }

          return ListView.builder(
            itemCount: professores.length,
            itemBuilder: (context, index) {
              final professor = professores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(professor['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(professor['materia']),
                      if (professor['telefone'] != null)
                        Text(professor['telefone']),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarProfessor(professor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _excluirProfessor(professor['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _limparFormulario();
          _abrirFormulario();
        },
      ),
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