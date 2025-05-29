import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/turma_service.dart';
import '../models/turma.dart';

// Classe Sala (simulação ou adapte para seu backend)
class Sala {
  final int id;
  final String nome;

  Sala({required this.id, required this.nome});
}

class EnsalamentoPage extends StatefulWidget {
  const EnsalamentoPage({super.key});

  @override
  State<EnsalamentoPage> createState() => _EnsalamentoPageState();
}

class _EnsalamentoPageState extends State<EnsalamentoPage> {
  final supabase = Supabase.instance.client;

  List<Sala> salas = [
    Sala(id: 1, nome: 'Sala 101'),
    Sala(id: 2, nome: 'Sala 102'),
    Sala(id: 3, nome: 'Laboratório 1'),
  ];

  List<Turma> turmas = [];

  // Cada sala pode ter duas turmas selecionadas, para 1º e 2º horário
  Map<int, Map<String, Turma?>> turmasSelecionadas = {};

  bool loadingTurmas = true;

  @override
  void initState() {
    super.initState();
    fetchTurmas();

    // Inicializa o mapa com null para cada horário
    for (var sala in salas) {
      turmasSelecionadas[sala.id] = {
        'primeiroHorario': null,
        'segundoHorario': null,
      };
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

  // Verifica se a turma já foi lançada no mesmo período em outra sala
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
      body: loadingTurmas
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 5, // 2 colunas
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
                children: salas.map((sala) {
                  final turmaPrimeiroHorario = turmasSelecionadas[sala.id]!['primeiroHorario'];
                  final turmaSegundoHorario = turmasSelecionadas[sala.id]!['segundoHorario'];

                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sala.nome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 1º Horário
                          const Text(
                            '1º Horário',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          DropdownButton<Turma>(
                            isExpanded: true,
                            value: turmaPrimeiroHorario,
                            hint: const Text('Selecione uma turma'),
                            items: turmas.map((turma) {
                              return DropdownMenuItem<Turma>(
                                value: turma,
                                child: Text(turma.nomeDoCurso),
                              );
                            }).toList(),
                            onChanged: (novaTurma) {
                              if (novaTurma == null) return;
                              if (turmaJaLancada(sala.id, 'primeiroHorario', novaTurma)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Turma já foi lançada neste período'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                setState(() {
                                  turmasSelecionadas[sala.id]!['primeiroHorario'] = novaTurma;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 20),

                          // 2º Horário
                          const Text(
                            '2º Horário',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          DropdownButton<Turma>(
                            isExpanded: true,
                            value: turmaSegundoHorario,
                            hint: const Text('Selecione uma turma'),
                            items: turmas.map((turma) {
                              return DropdownMenuItem<Turma>(
                                value: turma,
                                child: Text(turma.nomeDoCurso),
                              );
                            }).toList(),
                            onChanged: (novaTurma) {
                              if (novaTurma == null) return;
                              if (turmaJaLancada(sala.id, 'segundoHorario', novaTurma)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Turma já foi lançada neste período'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                setState(() {
                                  turmasSelecionadas[sala.id]!['segundoHorario'] = novaTurma;
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
