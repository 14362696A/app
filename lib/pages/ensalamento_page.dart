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
      final response = await supabase.from('turmas').select().order('nomeDoCurso');
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

  // Corrigido: Agora verifica nomeDoCurso + semestre, e só se ambos coincidirem
  bool turmaJaLancada(String slotId, String periodo, Turma turmaSelecionada, [int? semestreSelecionado]) {
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

  List<int> getSemestresDisponiveis(String slotId, String periodo, Turma turma) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ensalamento')),
      floatingActionButton: FloatingActionButton(
        onPressed: adicionarNovaSala,
        child: const Icon(Icons.add),
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
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<String>(
                              isExpanded: true,
                              value: salaAtual?.id,
                              hint: const Text('Selecione uma sala'),
                              items: salas
                                  .where((s) => !salasSelecionadasIds.contains(s.id) || s.id == salaAtual?.id)
                                  .map((s) => DropdownMenuItem<String>(
                                        value: s.id,
                                        child: Text(s.nome),
                                      ))
                                  .toList(),
                              onChanged: (novoId) {
                                if (novoId == null) return;
                                setState(() {
                                  dados['sala'] = salas.firstWhere((s) => s.id == novoId);
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            const Text('1º Horário', style: TextStyle(fontWeight: FontWeight.w600)),
                            DropdownButton<Turma>(
                              isExpanded: true,
                              value: primeiroHorario,
                              hint: const Text('Selecione uma turma'),
                              items: getCursosUnicos().map((turma) {
                                return DropdownMenuItem<Turma>(
                                  value: turma,
                                  child: Text(turma.nomeDoCurso),
                                );
                              }).toList(),
                              onChanged: (novaTurma) {
                                if (novaTurma == null) return;
                                setState(() {
                                  dados['primeiroHorario'] = novaTurma;
                                  dados['primeiroSemestre'] = null;
                                });
                              },
                            ),
                            if (primeiroHorario != null) ...[
                              const SizedBox(height: 5),
                              const Text('Semestre disponível:', style: TextStyle(fontWeight: FontWeight.w500)),
                              DropdownButton<int>(
                                isExpanded: true,
                                value: primeiroSemestre,
                                hint: const Text('Selecione o semestre'),
                                items: getSemestresDisponiveis(slotId, 'primeiroHorario', primeiroHorario)
                                    .map((sem) {
                                  return DropdownMenuItem<int>(
                                    value: sem,
                                    child: Text(sem.toString()),
                                  );
                                }).toList(),
                                onChanged: (semestre) {
                                  if (turmaJaLancada(slotId, 'primeiroHorario', primeiroHorario, semestre)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Esse semestre já está sendo usado por outra sala nesse horário'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      dados['primeiroSemestre'] = semestre;
                                    });
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Text('2º Horário', style: TextStyle(fontWeight: FontWeight.w600)),
                            DropdownButton<Turma>(
                              isExpanded: true,
                              value: segundoHorario,
                              hint: const Text('Selecione uma turma'),
                              items: getCursosUnicos().map((turma) {
                                return DropdownMenuItem<Turma>(
                                  value: turma,
                                  child: Text(turma.nomeDoCurso),
                                );
                              }).toList(),
                              onChanged: (novaTurma) {
                                if (novaTurma == null) return;
                                setState(() {
                                  dados['segundoHorario'] = novaTurma;
                                  dados['segundoSemestre'] = null;
                                });
                              },
                            ),
                            if (segundoHorario != null) ...[
                              const SizedBox(height: 5),
                              const Text('Semestre disponível:', style: TextStyle(fontWeight: FontWeight.w500)),
                              DropdownButton<int>(
                                isExpanded: true,
                                value: segundoSemestre,
                                hint: const Text('Selecione o semestre'),
                                items: getSemestresDisponiveis(slotId, 'segundoHorario', segundoHorario)
                                    .map((sem) {
                                  return DropdownMenuItem<int>(
                                    value: sem,
                                    child: Text(sem.toString()),
                                  );
                                }).toList(),
                                onChanged: (semestre) {
                                  if (turmaJaLancada(slotId, 'segundoHorario', segundoHorario, semestre)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Esse semestre já está sendo usado por outra sala nesse horário'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      dados['segundoSemestre'] = semestre;
                                    });
                                  }
                                },
                              ),
                            ],
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
