import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/turma_service.dart';
import '../models/turma.dart';

class Sala {
  final int id;
  final String nome;

  Sala({required this.id, required this.nome});

  factory Sala.fromMap(Map<String, dynamic> map) {
    return Sala(
      id: map['id'],
      nome: map['nome'],
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

  Map<int, Map<String, Turma?>> turmasSelecionadas = {
    -1: {'primeiroHorario': null, 'segundoHorario': null},
    -2: {'primeiroHorario': null, 'segundoHorario': null},
    -3: {'primeiroHorario': null, 'segundoHorario': null},
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

  bool turmaJaLancada(int salaId, String periodo, Turma turma) {
    for (var entry in turmasSelecionadas.entries) {
      int outraSalaId = entry.key;
      Turma? turmaNoPeriodo = entry.value[periodo];
      if (outraSalaId != salaId && turmaNoPeriodo != null && turmaNoPeriodo.id == turma.id) {
        return true;
      }
    }
    return false;
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
                  int slotId = entry.key;
                  Map<String, Turma?> horarios = entry.value;

                  Sala? salaAtual = salas.firstWhere(
                    (s) => s.id == slotId,
                    orElse: () => Sala(id: -1, nome: 'Selecione uma sala'),
                  );

                  List<int> salasSelecionadasIds = turmasSelecionadas.keys
                      .where((id) => id != slotId && id > 0)
                      .toList();

                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<int>(
                            value: salaAtual.id > 0 ? salaAtual.id : null,
                            isExpanded: true,
                            hint: const Text('Selecione uma sala'),
                            items: salas
                                .where((s) => s.id == salaAtual.id || !salasSelecionadasIds.contains(s.id))
                                .map((s) => DropdownMenuItem<int>(
                                      value: s.id,
                                      child: Text(s.nome),
                                    ))
                                .toList(),
                            onChanged: (novoId) {
                              if (novoId == null || novoId == slotId) return;
                              setState(() {
                                final dados = turmasSelecionadas.remove(slotId)!;
                                turmasSelecionadas[novoId] = dados;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text('1º Horário', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<Turma>(
                            isExpanded: true,
                            value: horarios['primeiroHorario'],
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
                                  turmasSelecionadas[slotId]!['primeiroHorario'] = novaTurma;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text('2º Horário', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<Turma>(
                            isExpanded: true,
                            value: horarios['segundoHorario'],
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
                                  turmasSelecionadas[slotId]!['segundoHorario'] = novaTurma;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
