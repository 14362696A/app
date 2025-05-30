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
      id: map['id'],
      nome: map['nome'],
    );
  }
}

class EnsalamentoCardData {
  String? salaId;
  Turma? primeiroHorario;
  Turma? segundoHorario;

  EnsalamentoCardData({
    this.salaId,
    this.primeiroHorario,
    this.segundoHorario,
  });
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

  List<EnsalamentoCardData> ensalamentoCards = [];

  bool loadingTurmas = true;
  bool loadingSalas = true;

  @override
  void initState() {
    super.initState();
    fetchTurmas();
    fetchSalas();
    ensalamentoCards = List.generate(3, (_) => EnsalamentoCardData());
  }

  Future<void> fetchSalas() async {
    try {
      final response = await supabase.from('salas').select().order('nome');
      if (response is List) {
        setState(() {
          salas = response.map((e) => Sala.fromMap(e)).toList();
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
      }
    } catch (e) {
      setState(() {
        loadingTurmas = false;
      });
      print('Erro ao buscar turmas: $e');
    }
  }

  bool turmaJaLancada(int cardIndex, String periodo, Turma turma) {
    for (int i = 0; i < ensalamentoCards.length; i++) {
      if (i == cardIndex) continue;
      final outroHorario = periodo == 'primeiroHorario'
          ? ensalamentoCards[i].primeiroHorario
          : ensalamentoCards[i].segundoHorario;
      if (outroHorario != null && outroHorario.id == turma.id) {
        return true;
      }
    }
    return false;
  }

  bool salaJaSelecionada(int cardIndex, String salaId) {
    for (int i = 0; i < ensalamentoCards.length; i++) {
      if (i == cardIndex) continue;
      if (ensalamentoCards[i].salaId == salaId) {
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
                children: List.generate(ensalamentoCards.length, (index) {
                  final cardData = ensalamentoCards[index];
                  Sala? salaAtual = salas.firstWhere(
                    (s) => s.id == cardData.salaId,
                    orElse: () => Sala(id: '', nome: 'Selecione uma sala'),
                  );

                  List<String> salasSelecionadasIds = ensalamentoCards
                      .asMap()
                      .entries
                      .where((entry) => entry.key != index)
                      .map((entry) => entry.value.salaId)
                      .whereType<String>()
                      .toList();

                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ícone de excluir card
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  ensalamentoCards.removeAt(index);
                                });
                              },
                            ),
                          ),

                          DropdownButton<String>(
                            isExpanded: true,
                            value:
                                salaAtual.id.isNotEmpty ? salaAtual.id : null,
                            hint: const Text('Selecione uma sala'),
                            items: [
                              if (salaAtual.id.isEmpty)
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Selecione uma sala'),
                                ),
                              ...salas
                                  .where((s) =>
                                      s.id == salaAtual.id ||
                                      !salasSelecionadasIds.contains(s.id))
                                  .map((s) => DropdownMenuItem<String>(
                                        value: s.id,
                                        child: Text(s.nome),
                                      ))
                            ],
                            onChanged: (novoId) {
                              if (novoId == null || novoId.isEmpty) return;

                              if (salaJaSelecionada(index, novoId)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Sala já selecionada em outro card'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                ensalamentoCards[index].salaId = novoId;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text('1º Horário',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<Turma>(
                            isExpanded: true,
                            value: cardData.primeiroHorario,
                            hint: const Text('Selecione uma turma'),
                            items: turmas.map((turma) {
                              return DropdownMenuItem<Turma>(
                                value: turma,
                                child: Text(turma.nomeDoCurso),
                              );
                            }).toList(),
                            onChanged: (novaTurma) {
                              if (novaTurma == null) return;
                              if (turmaJaLancada(
                                  index, 'primeiroHorario', novaTurma)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Turma já foi lançada neste período'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                setState(() {
                                  ensalamentoCards[index].primeiroHorario =
                                      novaTurma;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text('2º Horário',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<Turma>(
                            isExpanded: true,
                            value: cardData.segundoHorario,
                            hint: const Text('Selecione uma turma'),
                            items: turmas.map((turma) {
                              return DropdownMenuItem<Turma>(
                                value: turma,
                                child: Text(turma.nomeDoCurso),
                              );
                            }).toList(),
                            onChanged: (novaTurma) {
                              if (novaTurma == null) return;
                              if (turmaJaLancada(
                                  index, 'segundoHorario', novaTurma)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Turma já foi lançada neste período'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                setState(() {
                                  ensalamentoCards[index].segundoHorario =
                                      novaTurma;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            ensalamentoCards.add(EnsalamentoCardData());
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
