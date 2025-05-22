import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Turma {
  final int id;
  final String nomeDoCurso;
  final String periodo;
  final int qtdDeAlunos;
  final String semestre;
  final String observacoes;

  Turma({
    required this.id,
    required this.nomeDoCurso,
    required this.periodo,
    required this.qtdDeAlunos,
    required this.semestre,
    required this.observacoes,
  });

  factory Turma.fromMap(Map<String, dynamic> map) {
    return Turma(
      id: map['id'],
      nomeDoCurso: map['nome_do_curso'],
      periodo: map['periodo'],
      qtdDeAlunos: map['qtd_de_alunos'],
      semestre: map['semestre'] ?? '',
      observacoes: map['observacoes'] ?? '',
    );
  }
}

class TurmasPage extends StatefulWidget {
  const TurmasPage({super.key});

  @override
  State<TurmasPage> createState() => _TurmasPageState();
}

class _TurmasPageState extends State<TurmasPage> {
  final supabase = Supabase.instance.client;
  List<Turma> turmas = [];
  String periodoSelecionado = 'Matutino';

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  Future<void> _carregarTurmas() async {
    final response = await supabase
        .from('turmas')
        .select()
        .eq('periodo', periodoSelecionado);
    final data = response as List;
    setState(() {
      turmas = data.map((map) => Turma.fromMap(map)).toList();
    });
  }

  Future<void> _adicionarTurma(
      String nome, String periodo, int qtd, String semestre, String obs) async {
    try {
      final response = await supabase.from('turmas').insert({
        'nome_do_curso': nome,
        'periodo': periodo,
        'semestre': semestre,
        'qtd_de_alunos': qtd,
        'observacoes': obs,
      }).select();
      if (response.isNotEmpty) {
        final novaTurma = Turma.fromMap(response.first);
        setState(() {
          turmas.add(novaTurma);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _showAddTurmaDialog() {
    final nomeController = TextEditingController();
    final qtdController = TextEditingController();
    final semestreController = TextEditingController();
    final obsController = TextEditingController();
    String? periodoDialogSelecionado = periodoSelecionado;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar Nova Turma'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration:
                          const InputDecoration(labelText: 'Nome do Curso'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: periodoDialogSelecionado,
                      items: const [
                        DropdownMenuItem(
                            value: 'Matutino', child: Text('Matutino')),
                        DropdownMenuItem(
                            value: 'Noturno', child: Text('Noturno')),
                      ],
                      onChanged: (value) => setStateDialog(
                          () => periodoDialogSelecionado = value),
                      decoration: const InputDecoration(labelText: 'Período'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qtdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Quantidade de Alunos'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: semestreController,
                      decoration: const InputDecoration(labelText: 'Semestre'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: obsController,
                      decoration:
                          const InputDecoration(labelText: 'Observações'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (periodoDialogSelecionado == null) return;
                    final nome = nomeController.text;
                    final qtd = int.tryParse(qtdController.text) ?? 0;
                    final semestre = semestreController.text;
                    final obs = obsController.text;
                    await _adicionarTurma(
                        nome, periodoDialogSelecionado!, qtd, semestre, obs);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmasFiltradas =
        turmas.where((t) => t.periodo == periodoSelecionado).toList();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Turmas', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTurmaDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: 120,
              child: DropdownButton<String>(
                value: periodoSelecionado,
                isExpanded: true,
                underline: Container(),
                alignment: Alignment.center,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                onChanged: (String? newValue) {
                  setState(() {
                    periodoSelecionado = newValue!;
                  });
                  _carregarTurmas();
                },
                items: <String>['Matutino', 'Noturno'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, textAlign: TextAlign.center),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: turmasFiltradas.isEmpty
                  ? Center(
                      child:
                          Text('Nenhuma turma no período $periodoSelecionado.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: turmasFiltradas.length,
                      itemBuilder: (ctx, index) {
                        final turma = turmasFiltradas[index];
                        return Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(turma.nomeDoCurso,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                _buildInfoItem(
                                    Icons.numbers, 'ID: ${turma.id}'),
                                _buildInfoItem(Icons.people,
                                    'Alunos: ${turma.qtdDeAlunos}'),
                                _buildInfoItem(Icons.calendar_today,
                                    'Semestre: ${turma.semestre}'),
                                _buildInfoItem(Icons.room, turma.observacoes),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
