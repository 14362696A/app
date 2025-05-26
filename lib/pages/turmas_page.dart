import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/turma.dart';
import '../repositories/turma_repository.dart';
import 'package:uuid/uuid.dart';

class TurmasPage extends StatefulWidget {
  const TurmasPage({super.key});

  @override
  State<TurmasPage> createState() => _TurmasPageState();
}

//DEIXAR GRID IGUAL SALAS

class _TurmasPageState extends State<TurmasPage> {
  List<Turma> todasAsTurmas = []; // Sua lista original
  String turnoSelecionado = 'Noturno';
  final List<String> turnos = ['Matutino', 'Vespertino', 'Noturno'];
  final Uuid uuid = Uuid();
  final TurmaRepository turmaRepository = TurmaRepository();
  List<Turma> turmas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarTurmas();
  }

  Future<void> carregarTurmas() async {
    setState(() => isLoading = true);
    try {
      final listaTurmas = await turmaRepository.fetchTurmas();
      setState(() {
        turmas = listaTurmas;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar turmas: $e')),
      );
    }
  }

  void abrirFormularioEdicao(Turma turma) {
    final formKey = GlobalKey<FormState>();
    final nomeDoCursoCtrl = TextEditingController(text: turma.nomeDoCurso);
    final turnoCtrl = TextEditingController(text: turma.turno);
    final semestreCtrl = TextEditingController(text: turma.semestre.toString());
    final qtdAlunosCtrl =
        TextEditingController(text: turma.qtdDeAlunos.toString());
    final observacoesCtrl = TextEditingController(text: turma.observacoes);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar ${turma.nomeDoCurso}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeDoCursoCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Curso'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                TextField(
                  controller: turnoCtrl,
                  decoration: InputDecoration(labelText: 'Turno'),
                ),
                TextFormField(
                  controller: semestreCtrl,
                  decoration: const InputDecoration(labelText: 'Semestre'),
                ),
                TextFormField(
                  controller: qtdAlunosCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Quantidade de Alunos'),
                ),
                TextFormField(
                  controller: observacoesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações'),
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
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final turmaEditada = Turma(
                  id: turma.id,
                  nomeDoCurso: nomeDoCursoCtrl.text.trim(),
                  turno: turnoCtrl.text.trim(),
                  semestre: int.tryParse(semestreCtrl.text.trim()) ?? 0,
                  qtdDeAlunos: int.tryParse(qtdAlunosCtrl.text.trim()) ?? 0,
                  observacoes: observacoesCtrl.text.trim(),
                );

                await turmaRepository.salvarTurma(turmaEditada);
                Navigator.pop(context);
                carregarTurmas();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Turma atualizada com sucesso')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void abrirFormularioCriacao() {
    final formKey = GlobalKey<FormState>();
    final nomeDoCursoCtrl = TextEditingController();
    final semestreCtrl = TextEditingController();
    final qtdAlunosCtrl = TextEditingController();
    final observacoesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Criar nova Turma'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeDoCursoCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Curso'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o nome' : null,
                ),

                // Dropdown de Turno
                DropdownButtonFormField<String>(
                  value: turnoSelecionado,
                  decoration: const InputDecoration(labelText: 'Turno'),
                  items: ['Matutino', 'Vespertino', 'Noturno']
                      .map((turno) => DropdownMenuItem(
                            value: turno,
                            child: Text(turno),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => turnoSelecionado = value);
                    }
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Selecione um turno' : null,
                ),

                TextFormField(
                  controller: semestreCtrl,
                  decoration: const InputDecoration(labelText: 'Semestre'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o semestre' : null,
                ),

                TextFormField(
                  controller: qtdAlunosCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Quantidade de Alunos'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Informe a quantidade de alunos'
                      : null,
                ),

                TextFormField(
                  controller: observacoesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações'),
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
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final novaTurma = Turma(
                  id: uuid.v4(),
                  nomeDoCurso: nomeDoCursoCtrl.text.trim(),
                  turno: turnoSelecionado,
                  semestre: int.tryParse(semestreCtrl.text.trim()) ?? 0,
                  qtdDeAlunos: int.tryParse(qtdAlunosCtrl.text) ?? 0,
                  observacoes: observacoesCtrl.text.trim(),
                );

                await turmaRepository.salvarTurma(novaTurma);
                Navigator.pop(context);
                carregarTurmas();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Turma criada com sucesso')),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void confirmarExclusao(Turma turma) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir ${turma.nomeDoCurso}?'),
        content: const Text('Confirma exclusão da turma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await turmaRepository.excluirTurma(turma.id);
              Navigator.pop(context);
              carregarTurmas();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Turma excluída com sucesso')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget buildListaTurmas(List<Turma> lista) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lista.isEmpty) {
      return const Center(child: Text('Nenhuma turma cadastrada.'));
    }

    final screenWidth = MediaQuery.of(context).size.width;

    final crossAxisCount = screenWidth < 600
        ? 1
        : screenWidth < 1200
            ? 2
            : screenWidth < 1400
                ? 3
                : screenWidth < 1600
                    ? 4
                    : 5;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3 / 2.3,
      ),
      itemCount: lista.length,
      itemBuilder: (_, index) {
        final turma = lista[index];
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '${turma.nomeDoCurso} - ${turma.semestre}º Período',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black, // cor normal
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 16, thickness: 1),
                Text('Turno: ${turma.turno}',
                    style: const TextStyle(fontSize: 14)),
                Text('Semestre: ${turma.semestre}',
                    style: const TextStyle(fontSize: 14)),
                Text('Alunos: ${turma.qtdDeAlunos}',
                    style: const TextStyle(fontSize: 14)),
                if (turma.observacoes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Obs: ${turma.observacoes}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => abrirFormularioEdicao(turma),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmarExclusao(turma),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSpeedDial() {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      overlayOpacity: 0.4,
      backgroundColor: Colors.blue,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: 'Criar Turma',
          onTap: abrirFormularioCriacao,
        ),
        SpeedDialChild(
          child: const Icon(Icons.refresh),
          label: 'Atualizar',
          onTap: carregarTurmas,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmasFiltradas = turnoSelecionado == 'Todos'
        ? turmas
        : turmas.where((t) => t.turno == turnoSelecionado).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          titleSpacing: 16,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Turmas'),
              DropdownButton<String>(
                value: turnoSelecionado,
                underline: const SizedBox(),
                onChanged: (String? novoTurno) {
                  if (novoTurno != null) {
                    setState(() {
                      turnoSelecionado = novoTurno;
                    });
                  }
                },
                items: turnos.map((turno) {
                  return DropdownMenuItem<String>(
                    value: turno,
                    child: Text(turno),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : turmasFiltradas.isEmpty
              ? const Center(child: Text('Nenhuma turma cadastrada.'))
              : buildListaTurmas(
                  turmasFiltradas), // <<< AQUI É O NOVO MÉTODO COM GRID
      floatingActionButton: buildSpeedDial(),
    );
  }
}
