import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/turma_service.dart';
import '../models/turma.dart';

class Sala {
  final String id;
  final String nome;

  Sala({required this.id, required this.nome});

  factory Sala.fromMap(Map<String, dynamic> map) {
    return Sala(
      id: map['id'] as String,
      nome: map['nome'] as String,
    );
  }
}

class EnsalamentoPage extends StatefulWidget {
  const EnsalamentoPage({super.key});

  @override
  State<EnsalamentoPage> createState() => _EnsalamentoPageState();
}

class _EnsalamentoPageState extends State<EnsalamentoPage> {
  final supabase = Supabase.instance.client;

  List<Sala> salas = [];
  List<Turma> turmas = [];

  int cardCounter = 3;
  Map<String, Map<String, dynamic>> turmasSelecionadas = {
    '-1': {
      'sala': null,
      'primeiroHorario': null,
      'primeiroSemestre': null,
      'segundoHorario': null,
      'segundoSemestre': null,
    },
    '-2': {
      'sala': null,
      'primeiroHorario': null,
      'primeiroSemestre': null,
      'segundoHorario': null,
      'segundoSemestre': null,
    },
    '-3': {
      'sala': null,
      'primeiroHorario': null,
      'primeiroSemestre': null,
      'segundoHorario': null,
      'segundoSemestre': null,
    },
  };

  bool loadingTurmas = true;
  bool loadingSalas = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    fetchTurmas();
    fetchSalas();
  }

  Future<void> fetchSalas() async {
    try {
      final response = await supabase.from('salas').select().order('nome');
      if (response is List) {
        setState(() {
          salas = response.map((e) => Sala.fromMap(e)).toList();
          loadingSalas = false;
        });
      } else {
        setState(() {
          loadingSalas = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingSalas = false;
      });
      print('Erro ao buscar salas: $e');
    }
  }

  Future<void> fetchTurmas() async {
    try {
      final response =
          await supabase.from('turmas').select().order('nomeDoCurso');
      if (response is List) {
        setState(() {
          turmas = response.map((e) => Turma.fromMap(e)).toList();
          loadingTurmas = false;
        });
      } else {
        setState(() {
          loadingTurmas = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingTurmas = false;
      });
      print('Erro ao buscar turmas: $e');
    }
  }

  bool turmaJaLancada(String slotId, String periodo, Turma turmaSelecionada,
      [int? semestreSelecionado]) {
    for (var entry in turmasSelecionadas.entries) {
      String outraSalaId = entry.key;
      if (outraSalaId == slotId) continue;

      Turma? outraTurma = entry.value[periodo] as Turma?;
      int? outroSemestre = periodo == 'primeiroHorario'
          ? entry.value['primeiroSemestre']
          : entry.value['segundoSemestre'];

      if (outraTurma != null &&
          outraTurma.nomeDoCurso == turmaSelecionada.nomeDoCurso &&
          outroSemestre != null &&
          semestreSelecionado != null &&
          outroSemestre == semestreSelecionado) {
        return true;
      }
    }
    return false;
  }

  List<Turma> getCursosUnicos() {
    final Map<String, Turma> unicos = {};
    for (var turma in turmas) {
      if (!unicos.containsKey(turma.nomeDoCurso)) {
        unicos[turma.nomeDoCurso] = turma;
      }
    }
    return unicos.values.toList();
  }

  List<int> getSemestresDisponiveis(
      String slotId, String periodo, Turma turma) {
    final curso = turma.nomeDoCurso;
    final todosSemestres = turmas
        .where((t) => t.nomeDoCurso == curso)
        .map((t) => t.semestre)
        .toSet();

    final semestresUsados = turmasSelecionadas.entries
        .where((e) => e.key != slotId)
        .map((e) {
          final outraTurma = e.value[periodo] as Turma?;
          final outroSemestre = periodo == 'primeiroHorario'
              ? e.value['primeiroSemestre']
              : e.value['segundoSemestre'];
          return (outraTurma?.nomeDoCurso == curso) ? outroSemestre : null;
        })
        .whereType<int>()
        .toSet();

    final disponiveis = todosSemestres.difference(semestresUsados).toList();
    disponiveis.sort();
    return disponiveis;
  }

  void adicionarNovaSala() {
    setState(() {
      cardCounter++;
      turmasSelecionadas['-${cardCounter}'] = {
        'sala': null,
        'primeiroHorario': null,
        'primeiroSemestre': null,
        'segundoHorario': null,
        'segundoSemestre': null,
      };
    });
  }
//################################################################# SALVAR
  Future<void> salvarEnsalamentos() async {
    setState(() {
      saving = true;
    });

    try {
      final List<Map<String, dynamic>> dadosParaSalvar = [];

      turmasSelecionadas.forEach((key, dados) {
        final Sala? sala = dados['sala'] as Sala?;
        if (sala == null) return; // pula se não selecionou sala

        final Turma? primeiroHorario = dados['primeiroHorario'] as Turma?;
        final int? primeiroSemestre = dados['primeiroSemestre'] as int?;

        final Turma? segundoHorario = dados['segundoHorario'] as Turma?;
        final int? segundoSemestre = dados['segundoSemestre'] as int?;

        dadosParaSalvar.add({
          'sala_id': sala.id,
          'primeiro_horario': primeiroHorario?.id,
          'primeiro_semestre': primeiroSemestre,
          'segundo_horario': segundoHorario?.id,
          'segundo_semestre': segundoSemestre,
        });
      });

      final response = await supabase.from('ensalamentos').upsert(
            dadosParaSalvar,
            onConflict: 'id',
          );

      if (response == null) {
        throw Exception('Erro ao salvar ensalamento');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ensalamentos salvos com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() {
        saving = false;
      });
    }
  }
//################################################################# SALVAR
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ensalamento')),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.green,
            heroTag: 'btnSalvar',
            onPressed: saving ? null : salvarEnsalamentos,
            child: saving
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Icon(Icons.save),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'btnAdicionar',
            onPressed: adicionarNovaSala,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: loadingTurmas || loadingSalas
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
                children: turmasSelecionadas.entries.map((entry) {
                  String slotId = entry.key;
                  Map<String, dynamic> dados = entry.value;

                  Sala? salaAtual = dados['sala'] as Sala?;
                  List<String> salasSelecionadasIds = turmasSelecionadas.entries
                      .where((e) => e.key != slotId)
                      .map((e) => (e.value['sala'] as Sala?)?.id)
                      .whereType<String>()
                      .toList();

                  Turma? primeiroHorario = dados['primeiroHorario'] as Turma?;
                  int? primeiroSemestre = dados['primeiroSemestre'] as int?;
                  Turma? segundoHorario = dados['segundoHorario'] as Turma?;
                  int? segundoSemestre = dados['segundoSemestre'] as int?;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dropdown Sala
                            DropdownButtonFormField<Sala>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Sala',
                              ),
                              value: salaAtual,
                              items: salas
                                  .where((s) =>
                                      !salasSelecionadasIds.contains(s.id))
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.nome),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (Sala? novaSala) {
                                setState(() {
                                  turmasSelecionadas[slotId]!['sala'] =
                                      novaSala;
                                  // Limpar turmas e semestres ao trocar sala
                                  turmasSelecionadas[slotId]![
                                      'primeiroHorario'] = null;
                                  turmasSelecionadas[slotId]![
                                      'primeiroSemestre'] = null;
                                  turmasSelecionadas[slotId]![
                                      'segundoHorario'] = null;
                                  turmasSelecionadas[slotId]![
                                      'segundoSemestre'] = null;
                                });
                              },
                            ),
                            const SizedBox(height: 8),

                            // Primeiro horário - Turma
                            DropdownButtonFormField<Turma>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Primeiro Horário',
                              ),
                              value: primeiroHorario,
                              items: getCursosUnicos()
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.nomeDoCurso),
                                      ))
                                  .toList(),
                              onChanged: (Turma? novaTurma) {
                                if (novaTurma != null) {
                                  final semestresDisp = getSemestresDisponiveis(
                                    slotId,
                                    'primeiroHorario',
                                    novaTurma,
                                  );
                                  if (semestresDisp.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Semestres disponíveis para essa turma estão esgotados.'),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    turmasSelecionadas[slotId]![
                                        'primeiroHorario'] = novaTurma;
                                    turmasSelecionadas[slotId]![
                                            'primeiroSemestre'] =
                                        semestresDisp.first;
                                  });
                                }
                              },
                            ),

                            // Primeiro semestre
                            if (primeiroHorario != null)
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Semestre Primeiro Horário',
                                ),
                                value: primeiroSemestre,
                                items: getSemestresDisponiveis(slotId,
                                        'primeiroHorario', primeiroHorario)
                                    .map((sem) => DropdownMenuItem(
                                          value: sem,
                                          child: Text(sem.toString()),
                                        ))
                                    .toList(),
                                onChanged: (int? sem) {
                                  if (sem != null) {
                                    setState(() {
                                      turmasSelecionadas[slotId]![
                                          'primeiroSemestre'] = sem;
                                    });
                                  }
                                },
                              ),

                            const SizedBox(height: 8),

                            // Segundo horário - Turma
                            DropdownButtonFormField<Turma>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Segundo Horário',
                              ),
                              value: segundoHorario,
                              items: getCursosUnicos()
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.nomeDoCurso),
                                      ))
                                  .toList(),
                              onChanged: (Turma? novaTurma) {
                                if (novaTurma != null) {
                                  final semestresDisp = getSemestresDisponiveis(
                                    slotId,
                                    'segundoHorario',
                                    novaTurma,
                                  );
                                  if (semestresDisp.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Semestres disponíveis para essa turma estão esgotados.'),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    turmasSelecionadas[slotId]![
                                        'segundoHorario'] = novaTurma;
                                    turmasSelecionadas[slotId]![
                                            'segundoSemestre'] =
                                        semestresDisp.first;
                                  });
                                }
                              },
                            ),

                            // Segundo semestre
                            if (segundoHorario != null)
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Semestre Segundo Horário',
                                ),
                                value: segundoSemestre,
                                items: getSemestresDisponiveis(slotId,
                                        'segundoHorario', segundoHorario)
                                    .map((sem) => DropdownMenuItem(
                                          value: sem,
                                          child: Text(sem.toString()),
                                        ))
                                    .toList(),
                                onChanged: (int? sem) {
                                  if (sem != null) {
                                    setState(() {
                                      turmasSelecionadas[slotId]![
                                          'segundoSemestre'] = sem;
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
