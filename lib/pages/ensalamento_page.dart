import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ensalamento.dart';
import '../repositories/ensalamento_repository.dart';

// DEFINIÇÃO PRINCIPAL DO WIDGET
class EnsalamentoPage extends StatefulWidget {
  const EnsalamentoPage({super.key});

  @override
  State<EnsalamentoPage> createState() => _EnsalamentoPageState();
}

// STATE COMPLETO
class _EnsalamentoPageState extends State<EnsalamentoPage> {
  final SupabaseClient _client = Supabase.instance.client;
  late EnsalamentoRepository _repository;

  final ScrollController _scrollController = ScrollController();

  List<Ensalamento> _ensalamentos = [];
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _salas = [];
  List<Map<String, dynamic>> _turmas = [];

  // Filtros para seleção sequencial
  String? _cursoFiltro;
  String? _semestreFiltro;
  String? _turnoFiltro;

  // Filtros individuais para cada curso
  String? _primeiroCursoNome;
  String? _primeiroCursoSemestre;
  String? _primeiroCursoTurno;
  String? _segundoCursoNome;
  String? _segundoCursoSemestre;
  String? _segundoCursoTurno;

  // Novos filtros
  String? _blocoFiltro;

  List<String> _getNomesCursos() {
    final cursos = _turmas.map((t) => (t['nomeDoCurso'] ?? '').toString()).toSet().toList();
    cursos.removeWhere((s) => s.isEmpty);
    cursos.sort();
    return cursos;
  }

  List<String> _getSemestres(String? nomeCurso) {
    if (nomeCurso == null) return [];
    final semestres = _turmas
        .where((t) => t['nomeDoCurso'] == nomeCurso)
        .map((t) => (t['semestre'] ?? '').toString())
        .toSet()
        .toList();
    semestres.removeWhere((s) => s.isEmpty);
    semestres.sort((a, b) => int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? 0);
    return semestres;
  }

  List<String> _getTurnos(String? nomeCurso, String? semestre) {
    if (nomeCurso == null || semestre == null) return [];
    final turnos = _turmas
        .where((t) => t['nomeDoCurso'] == nomeCurso && (t['semestre']?.toString() ?? '') == semestre)
        .map((t) => (t['turno'] ?? '').toString())
        .toSet()
        .toList();
    turnos.removeWhere((s) => s.isEmpty);
    turnos.sort();
    return turnos;
  }

  List<Map<String, dynamic>> get turmasFiltradas {
    if (_cursoFiltro == null || _semestreFiltro == null || _turnoFiltro == null) return [];
    return _turmas.where((t) =>
      t['nomeDoCurso'] == _cursoFiltro &&
      (t['semestre']?.toString() ?? '') == _semestreFiltro &&
      (t['turno'] ?? '').toString() == _turnoFiltro
    ).toList();
  }

  List<Map<String, dynamic>> _getTurmasFiltradas(String? nomeCurso, String? semestre, String? turno) {
    if (nomeCurso == null || semestre == null || turno == null) return [];
    return _turmas.where((t) =>
      t['nomeDoCurso'] == nomeCurso &&
      (t['semestre']?.toString() ?? '') == semestre &&
      (t['turno'] ?? '').toString() == turno
    ).toList();
  }

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
    _carregarSalasETurmas();
    _carregarEnsalamentos();
    _ouvirAlteracoesEmTempoReal();
  }

  Future<void> _carregarEnsalamentos() async {
    final response = await _client.from('ensalamentos').select().order('created_at').execute();
    if (response.status == 200) {
      setState(() {
        _ensalamentos = (response.data as List)
            .map((e) => Ensalamento.fromMap(e))
            .toList();
      });
    }
  }

  void _ouvirAlteracoesEmTempoReal() {
    _client
        .from('ensalamentos')
        .stream(primaryKey: ['id'])
        .listen((data) {
          debugPrint('Alteração detectada: $data');
          _carregarEnsalamentos();
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
    Map<String, dynamic>? turma1;
    Map<String, dynamic>? turma2;
    try {
      final t1 = _turmas.firstWhere((t) => t['id'] == ensalamento.primeiroCursoId);
      turma1 = t1;
    } catch (_) {
      turma1 = null;
    }
    try {
      final t2 = _turmas.firstWhere((t) => t['id'] == ensalamento.segundoCursoId);
      turma2 = t2;
    } catch (_) {
      turma2 = null;
    }
    setState(() {
      _isEditando = true;
      _editandoId = ensalamento.id;
      _selectedSalaId = ensalamento.salaId;
      _diaSemana = ensalamento.diaDaSemana;
      _primeiroCursoId = ensalamento.primeiroCursoId;
      _segundoCursoId = ensalamento.segundoCursoId;
      _primeiroCursoNome = turma1 != null ? turma1['nomeDoCurso'] as String : null;
      _primeiroCursoSemestre = turma1 != null ? turma1['semestre']?.toString() : null;
      _primeiroCursoTurno = turma1 != null ? turma1['turno']?.toString() : null;
      _segundoCursoNome = turma2 != null ? turma2['nomeDoCurso'] as String : null;
      _segundoCursoSemestre = turma2 != null ? turma2['semestre']?.toString() : null;
      _segundoCursoTurno = turma2 != null ? turma2['turno']?.toString() : null;
    });
    Future.delayed(Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _excluir(String id) async {
    await _repository.excluir(id);
  }

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

  @override
  Widget build(BuildContext context) {
    final diasDaSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'];

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cadastro de Ensalamentos:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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
                      // Seletor do PRIMEIRO CURSO
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _primeiroCursoNome,
                              decoration: const InputDecoration(labelText: 'Nome do Curso', border: OutlineInputBorder()),
                              items: _getNomesCursos().map((nome) => DropdownMenuItem(value: nome, child: Text(nome))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _primeiroCursoNome = val;
                                  _primeiroCursoSemestre = null;
                                  _primeiroCursoTurno = null;
                                  _primeiroCursoId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _primeiroCursoSemestre,
                              decoration: const InputDecoration(labelText: 'Semestre', border: OutlineInputBorder()),
                              items: _getSemestres(_primeiroCursoNome).map((sem) => DropdownMenuItem(value: sem, child: Text(sem))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _primeiroCursoSemestre = val;
                                  _primeiroCursoTurno = null;
                                  _primeiroCursoId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _primeiroCursoTurno,
                              decoration: const InputDecoration(labelText: 'Turno', border: OutlineInputBorder()),
                              items: _getTurnos(_primeiroCursoNome, _primeiroCursoSemestre).map((turno) => DropdownMenuItem(value: turno, child: Text(turno))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _primeiroCursoTurno = val;
                                  // Atualiza o id do curso selecionado
                                  final turmas = _getTurmasFiltradas(_primeiroCursoNome, _primeiroCursoSemestre, _primeiroCursoTurno);
                                  _primeiroCursoId = turmas.isNotEmpty ? turmas.first['id'] as String : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Seletor do SEGUNDO CURSO
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _segundoCursoNome,
                              decoration: const InputDecoration(labelText: 'Nome do Curso', border: OutlineInputBorder()),
                              items: _getNomesCursos().map((nome) => DropdownMenuItem(value: nome, child: Text(nome))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _segundoCursoNome = val;
                                  _segundoCursoSemestre = null;
                                  _segundoCursoTurno = null;
                                  _segundoCursoId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _segundoCursoSemestre,
                              decoration: const InputDecoration(labelText: 'Semestre', border: OutlineInputBorder()),
                              items: _getSemestres(_segundoCursoNome).map((sem) => DropdownMenuItem(value: sem, child: Text(sem))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _segundoCursoSemestre = val;
                                  _segundoCursoTurno = null;
                                  _segundoCursoId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _segundoCursoTurno,
                              decoration: const InputDecoration(labelText: 'Turno', border: OutlineInputBorder()),
                              items: _getTurnos(_segundoCursoNome, _segundoCursoSemestre).map((turno) => DropdownMenuItem(value: turno, child: Text(turno))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _segundoCursoTurno = val;
                                  final turmas = _getTurmasFiltradas(_segundoCursoNome, _segundoCursoSemestre, _segundoCursoTurno);
                                  _segundoCursoId = turmas.isNotEmpty ? turmas.first['id'] as String : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Campo: Sala
                      _buildDropdown<String>(
                        label: 'Sala',
                        value: _selectedSalaId,
                        items: _salas.map((sala) {
                          return DropdownMenuItem<String>(
                            value: sala['id'] as String,
                            child: Text(sala['nome'] as String),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSalaId = val),
                        validator: (val) =>
                            val == null ? 'Selecione uma sala' : null,
                      ),
                      // Campo: Dia da semana
                      _buildDropdown<String>(
                        label: 'Dia da semana',
                        value: _diaSemana,
                        items: diasDaSemana.map((d) {
                          return DropdownMenuItem(
                            value: d.toLowerCase(),
                            child: Text(d),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _diaSemana = val),
                        validator: (val) =>
                            val == null ? 'Escolha um dia da semana' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                  _isEditando ? Icons.save : Icons.add),
                              label:
                                  Text(_isEditando ? 'Atualizar' : 'Criar'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
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
            // Filtros para a lista de ensalamentos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Filtro por Bloco (com opção de não filtrar)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _blocoFiltro,
                        decoration: const InputDecoration(labelText: 'Bloco', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Todos os Blocos')),
                          ..._salas.map((sala) => sala['bloco']?.toString() ?? '').toSet().where((b) => b.isNotEmpty).map((bloco) => DropdownMenuItem(value: bloco, child: Text(bloco))).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _blocoFiltro = val;
                          });
                        },
                        isExpanded: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filtro por Turno
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _turnoFiltro,
                        decoration: const InputDecoration(labelText: 'Turno', border: OutlineInputBorder()),
                        items: _turmas.map((t) => (t['turno'] ?? '').toString()).toSet().where((t) => t.isNotEmpty).map((turno) => DropdownMenuItem(value: turno, child: Text(turno))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _turnoFiltro = val;
                          });
                        },
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ensalamentos cadastrados:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final ensalamentosFiltrados = _ensalamentos.where((e) {
                  // Filtro por bloco
                  final sala = _salas.firstWhere(
                    (s) => s['id'] == e.salaId,
                    orElse: () => <String, dynamic>{},
                  );
                  final blocoOk = _blocoFiltro == null || (_blocoFiltro?.isEmpty ?? true) || (sala['bloco']?.toString() == _blocoFiltro);
                  // Filtro por turno (primeiro ou segundo curso)
                  final turma1 = e.primeiroCursoId != null ? _turmas.firstWhere(
                    (t) => t['id'] == e.primeiroCursoId,
                    orElse: () => <String, dynamic>{},
                  ) : null;
                  final turma2 = e.segundoCursoId != null ? _turmas.firstWhere(
                    (t) => t['id'] == e.segundoCursoId,
                    orElse: () => <String, dynamic>{},
                  ) : null;
                  final turnoOk = _turnoFiltro == null || (_turnoFiltro?.isEmpty ?? true) ||
                    (turma1 != null && turma1['turno'] == _turnoFiltro) ||
                    (turma2 != null && turma2['turno'] == _turnoFiltro);
                  return blocoOk && turnoOk;
                }).toList();
                if (ensalamentosFiltrados.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Nenhum ensalamento cadastrado.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ensalamentosFiltrados.length,
                  itemBuilder: (context, index) {
                    final e = ensalamentosFiltrados[index];
                    final salaNome = _salas.firstWhere(
                      (s) => s['id'] == e.salaId,
                      orElse: () => {'nome': e.salaId},
                    )['nome'];
                    final primeiroCurso = e.primeiroCursoId != null
                        ? _turmas.firstWhere(
                            (t) => t['id'] == e.primeiroCursoId,
                            orElse: () => {'nomeDoCurso': 'Não encontrado', 'semestre': '', 'turno': ''},
                          )
                        : null;
                    final segundoCurso = e.segundoCursoId != null
                        ? _turmas.firstWhere(
                            (t) => t['id'] == e.segundoCursoId,
                            orElse: () => {'nomeDoCurso': 'Não encontrado', 'semestre': '', 'turno': ''},
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1º  ${primeiroCurso?['nomeDoCurso'] ?? 'Não encontrado'}\n'
                              '   Semestre: ${primeiroCurso?['semestre'] ?? '-'} | Turno: ${primeiroCurso?['turno'] ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2º  ${segundoCurso?['nomeDoCurso'] ?? 'Não encontrado'}\n'
                              '   Semestre: ${segundoCurso?['semestre'] ?? '-'} | Turno: ${segundoCurso?['turno'] ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
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
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Excluir',
                              onPressed: () => _excluir(e.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
