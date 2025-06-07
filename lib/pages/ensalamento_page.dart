import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ensalamento.dart';
import '../repositories/ensalamento_repository.dart';

class EnsalamentoPage extends StatefulWidget {
  const EnsalamentoPage({Key? key}) : super(key: key);

  @override
  State<EnsalamentoPage> createState() => _EnsalamentoPageState();
}

class _EnsalamentoPageState extends State<EnsalamentoPage> {
  final SupabaseClient _client = Supabase.instance.client;
  late EnsalamentoRepository _repository;

  List<Ensalamento> _ensalamentos = [];
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _salas = [];
  List<Map<String, dynamic>> _turmas = [];

  String? _selectedSalaId;
  String? _diaSemana;
  String? _primeiroCursoId;
  String? _segundoCursoId;

  bool _isEditando = false;
  String? _editandoId;

  @override
  void initState() {
    super.initState();
    _repository = EnsalamentoRepository(_client);
    _carregarEnsalamentos();
    _carregarSalasETurmas();
  }

Future<void> _carregarEnsalamentos() async {
  final lista = await _repository.listarTodos();
  print('Ensamentos carregados: ${lista.length}');
  setState(() {
    _ensalamentos = lista;
  });
}

  Future<void> _carregarSalasETurmas() async {
    final salasResponse = await _client.from('salas').select().execute();
    final turmasResponse = await _client.from('turmas').select().execute();

    if (salasResponse.status == 200 && turmasResponse.status == 200) {
      setState(() {
        _salas = List<Map<String, dynamic>>.from(salasResponse.data as List);
        _turmas = List<Map<String, dynamic>>.from(turmasResponse.data as List);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro ao carregar salas ou turmas. Status: ${salasResponse.status}, ${turmasResponse.status}'),
        ),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final novo = Ensalamento(
      id: _editandoId ?? '',
      salaId: _selectedSalaId!,
      diaDaSemana: _diaSemana!,
      primeiroCursoId: _primeiroCursoId,
      segundoCursoId: _segundoCursoId,
      createdAt: DateTime.now(),
    );

    if (_isEditando && _editandoId != null) {
      await _repository.editar(_editandoId!, novo.toMap());
    } else {
      await _repository.criar(novo);
    }

    _limparFormulario();
    await _carregarEnsalamentos();
  }

  void _limparFormulario() {
    setState(() {
      _formKey.currentState?.reset();
      _selectedSalaId = null;
      _diaSemana = null;
      _primeiroCursoId = null;
      _segundoCursoId = null;
      _isEditando = false;
      _editandoId = null;
    });
  }

  void _carregarParaEdicao(Ensalamento ensalamento) {
    setState(() {
      _isEditando = true;
      _editandoId = ensalamento.id;
      _selectedSalaId = ensalamento.salaId;
      _diaSemana = ensalamento.diaDaSemana;
      _primeiroCursoId = ensalamento.primeiroCursoId;
      _segundoCursoId = ensalamento.segundoCursoId;
    });
  }

  Future<void> _excluir(String id) async {
    await _repository.excluir(id);
    await _carregarEnsalamentos();
  }

@override
Widget _buildDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
  FormFieldValidator<T>? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    ),
  );
}


Widget build(BuildContext context) {
  final diasDaSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'];

  return Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título posicionado manualmente
        Text(
            'Cadastro de Ensalamentos:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        const SizedBox(height: 8), // Espaçamento mais próximo do formulário
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDropdown<String>(
                    label: 'Sala',
                    value: _selectedSalaId,
                    items: _salas.map((sala) => DropdownMenuItem<String>(
                      value: sala['id'] as String,
                      child: Text(sala['nome'] as String),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedSalaId = val),
                    validator: (val) => val == null ? 'Selecione uma sala' : null,
                  ),
                  _buildDropdown<String>(
                    label: 'Dia da semana',
                    value: _diaSemana,
                    items: diasDaSemana.map((d) => DropdownMenuItem(
                      value: d.toLowerCase(),
                      child: Text(d),
                    )).toList(),
                    onChanged: (val) => setState(() => _diaSemana = val),
                    validator: (val) => val == null ? 'Escolha um dia da semana' : null,
                  ),
                  _buildDropdown<String>(
                    label: 'Primeiro curso',
                    value: _primeiroCursoId,
                    items: _turmas.map((turma) {
                      final nomeCurso = turma['nomeDoCurso'] ?? 'Sem nome';
                      final semestre = turma['semestre']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: turma['id'] as String,
                        child: Text('$nomeCurso - Semestre $semestre'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _primeiroCursoId = val),
                  ),

                    _buildDropdown<String>(
                      label: 'Segundo curso',
                      value: _segundoCursoId,
                      items: _turmas.map((turma) {
                        final nomeCurso = turma['nomeDoCurso'] ?? 'Sem nome';
                        final semestre = turma['semestre']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: turma['id'] as String,
                          child: Text('$nomeCurso - Semestre $semestre'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _segundoCursoId = val),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(_isEditando ? Icons.save : Icons.add),
                            label: Text(_isEditando ? 'Atualizar' : 'Criar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _salvar,
                          ),
                        ),
                        if (_isEditando) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancelar edição'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _limparFormulario,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Ensalamentos cadastrados:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _ensalamentos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Nenhum ensalamento cadastrado.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ensalamentos.length,
                  itemBuilder: (context, index) {
                    final e = _ensalamentos[index];

                    final salaNome = _salas.firstWhere(
                      (s) => s['id'] == e.salaId,
                      orElse: () => {'nome': e.salaId},
                    )['nome'];

                    final primeiroCurso = e.primeiroCursoId != null
                        ? _turmas.firstWhere(
                            (t) => t['id'] == e.primeiroCursoId,
                            orElse: () => {'nomeDoCurso': e.primeiroCursoId, 'semestre': ''}
                          )
                        : null;

                    final segundoCurso = e.segundoCursoId != null
                        ? _turmas.firstWhere(
                            (t) => t['id'] == e.segundoCursoId,
                            orElse: () => {'nomeDoCurso': e.segundoCursoId, 'semestre': ''}
                          )
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        title: Text(
                          '${e.diaDaSemana[0].toUpperCase()}${e.diaDaSemana.substring(1)} - Sala $salaNome',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '1º Curso: ${primeiroCurso?['nomeDoCurso']} - Semestre ${primeiroCurso?['semestre']}\n'
                          '2º Curso: ${segundoCurso?['nomeDoCurso']} - Semestre ${segundoCurso?['semestre']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo),
                              tooltip: 'Editar',
                              onPressed: () => _carregarParaEdicao(e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Excluir',
                              onPressed: () => _excluir(e.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    ),
  );
}

}
