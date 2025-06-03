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

  // Agora armazenamos sala, turma e semestre em cada horário para cada slot
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

  bool turmaJaLancada(String slotId, String periodo, Turma turma) {
    for (var entry in turmasSelecionadas.entries) {
      String outraSalaId = entry.key;
      Turma? turmaNoPeriodo = entry.value[periodo];
      if (outraSalaId != slotId && turmaNoPeriodo != null && turmaNoPeriodo.id == turma.id) {
        return true;
      }
    }
    return false;
  }

  List<int> getSemestresDisponiveis(Turma turma) {
    // Retorna lista de semestres únicos para o curso da turma
    final semestres = turmas
        .where((t) => t.nomeDoCurso == turma.nomeDoCurso)
        .map((t) => t.semestre)
        .toSet()
        .toList();
    semestres.sort();
    return semestres;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ensalamento'),
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
                              items: turmas.map((turma) {
                                return DropdownMenuItem<Turma>(
                                  value: turma,
                                  child: Text(turma.nomeDoCurso),
                                );
                              }).toList(),
                              onChanged: (novaTurma) {
                                if (novaTurma == null) return;
                                if (turmaJaLancada(slotId, 'primeiroHorario', novaTurma)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Turma já foi lançada neste período'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    dados['primeiroHorario'] = novaTurma;
                                    dados['primeiroSemestre'] = null; // reset semestre ao trocar turma
                                  });
                                }
                              },
                            ),
                            if (primeiroHorario != null) ...[
                              const SizedBox(height: 5),
                              const Text('Semestre disponível:', style: TextStyle(fontWeight: FontWeight.w500)),
                              DropdownButton<int>(
                                isExpanded: true,
                                value: primeiroSemestre,
                                hint: const Text('Selecione o semestre'),
                                items: getSemestresDisponiveis(primeiroHorario).map((sem) {
                                  return DropdownMenuItem<int>(
                                    value: sem,
                                    child: Text(sem.toString()),
                                  );
                                }).toList(),
                                onChanged: (semestre) {
                                  setState(() {
                                    dados['primeiroSemestre'] = semestre;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Text('2º Horário', style: TextStyle(fontWeight: FontWeight.w600)),
                            DropdownButton<Turma>(
                              isExpanded: true,
                              value: segundoHorario,
                              hint: const Text('Selecione uma turma'),
                              items: turmas.map((turma) {
                                return DropdownMenuItem<Turma>(
                                  value: turma,
                                  child: Text(turma.nomeDoCurso),
                                );
                              }).toList(),
                              onChanged: (novaTurma) {
                                if (novaTurma == null) return;
                                if (turmaJaLancada(slotId, 'segundoHorario', novaTurma)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Turma já foi lançada neste período'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    dados['segundoHorario'] = novaTurma;
                                    dados['segundoSemestre'] = null; // reset semestre ao trocar turma
                                  });
                                }
                              },
                            ),
                            if (segundoHorario != null) ...[
                              const SizedBox(height: 5),
                              const Text('Semestre disponível:', style: TextStyle(fontWeight: FontWeight.w500)),
                              DropdownButton<int>(
                                isExpanded: true,
                                value: segundoSemestre,
                                hint: const Text('Selecione o semestre'),
                                items: getSemestresDisponiveis(segundoHorario).map((sem) {
                                  return DropdownMenuItem<int>(
                                    value: sem,
                                    child: Text(sem.toString()),
                                  );
                                }).toList(),
                                onChanged: (semestre) {
                                  setState(() {
                                    dados['segundoSemestre'] = semestre;
                                  });
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
