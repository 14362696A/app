import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../services/sala_service.dart';

class Sala {
  final String nome;
  bool ativa = true;
  bool ar = false;
  bool tv = false;
  bool projetor = false;
  int cadeiras = 0;
  int cadeirasPcd = 0;
  int pcs = 0;

  Sala(this.nome);
}

class SalasPage extends StatefulWidget {
  const SalasPage({super.key});

  @override
  State<SalasPage> createState() => _SalasPageState();
}

class _SalasPageState extends State<SalasPage> {
  String filtroSelecionado = 'Bloco C';
  bool modoEdicao = false;

  final Map<String, List<Sala>> salasPorCategoria = {
    'Bloco C': List.generate(23, (i) => Sala('${i + 1}C')),
    'Bloco D': List.generate(19, (i) => Sala('${i + 1}D')),
    'Lab. INF.': List.generate(6, (i) => Sala('Lab ${i + 1}')),
    'Lab Saúde': List.generate(6, (i) => Sala('Lab Saúde ${i + 1}')),
  };

  void abrirFormularioEdicao(Sala sala) {
  final formKey = GlobalKey<FormState>();
  bool ativa = sala.ativa;
  bool ar = sala.ar;
  bool tv = sala.tv;
  bool projetor = sala.projetor;

  final cadeirasCtrl = TextEditingController(text: sala.cadeiras.toString());
  final cadeirasPcdCtrl = TextEditingController(text: sala.cadeirasPcd.toString());
  final pcsCtrl = TextEditingController(text: sala.pcs.toString());

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Editar ${sala.nome}'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<bool>(
                value: ativa,
                onChanged: (v) => ativa = v ?? true,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Ativa')),
                  DropdownMenuItem(value: false, child: Text('Inativa')),
                ],
                decoration: const InputDecoration(labelText: 'Sala'),
              ),
              DropdownButtonFormField<bool>(
                value: ar,
                onChanged: (v) => ar = v ?? false,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Ar: Sim')),
                  DropdownMenuItem(value: false, child: Text('Ar: Não')),
                ],
                decoration: const InputDecoration(labelText: 'Ar-condicionado'),
              ),
              DropdownButtonFormField<bool>(
                value: tv,
                onChanged: (v) => tv = v ?? false,
                items: const [
                  DropdownMenuItem(value: true, child: Text('TV: Sim')),
                  DropdownMenuItem(value: false, child: Text('TV: Não')),
                ],
                decoration: const InputDecoration(labelText: 'TV'),
              ),
              DropdownButtonFormField<bool>(
                value: projetor,
                onChanged: (v) => projetor = v ?? false,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Projetor: Sim')),
                  DropdownMenuItem(value: false, child: Text('Projetor: Não')),
                ],
                decoration: const InputDecoration(labelText: 'Projetor'),
              ),
              TextFormField(
                controller: cadeirasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qtd Cadeiras'),
              ),
              TextFormField(
                controller: cadeirasPcdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qtd Cadeiras PCD'),
              ),
              TextFormField(
                controller: pcsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qtd PCs'),
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
            sala.ativa = ativa;
            sala.ar = ar;
            sala.tv = tv;
            sala.projetor = projetor;
            sala.cadeiras = int.tryParse(cadeirasCtrl.text) ?? 0;
            sala.cadeirasPcd = int.tryParse(cadeirasPcdCtrl.text) ?? 0;
            sala.pcs = int.tryParse(pcsCtrl.text) ?? 0;

            await salvarSala(
              nome: sala.nome,
              bloco: filtroSelecionado,
              ativa: sala.ativa,
              ar: sala.ar,
              tv: sala.tv,
              projetor: sala.projetor,
              cadeiras: sala.cadeiras,
              cadeirasPcd: sala.cadeirasPcd,
              computadores: sala.pcs,
            );

            Navigator.pop(context); // Fecha o dialog

            // Atualiza a tela após o fechamento
            setState(() {});

            // Feedback ao usuário
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sala salva no banco de dados')),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final salas = salasPorCategoria[filtroSelecionado]!;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: filtroSelecionado,
              onChanged: (String? novoFiltro) {
                setState(() {
                  filtroSelecionado = novoFiltro!;
                });
              },
              items: salasPorCategoria.keys.map((categoria) {
                return DropdownMenuItem(
                  value: categoria,
                  child: Text(categoria),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: salas.length,
              itemBuilder: (context, index) {
                final sala = salas[index];
                return GestureDetector(
                  onTap: () {
                    if (modoEdicao) {
                      abrirFormularioEdicao(sala);
                    }
                  },
                  child: Card(
                    color: sala.ativa ? Colors.white : Colors.grey[300],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sala.nome,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Ar: ${sala.ar ? 'Sim' : 'Não'}'),
                          Text('TV: ${sala.tv ? 'Sim' : 'Não'}'),
                          Text('Projetor: ${sala.projetor ? 'Sim' : 'Não'}'),
                          Text('Cadeiras: ${sala.cadeiras}'),
                          Text('PCD: ${sala.cadeirasPcd}'),
                          Text('PCs: ${sala.pcs}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Inserir Sala',
            onTap: () {
              // lógica de adicionar nova sala (opcional)
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Editar Sala',
            onTap: () {
              setState(() {
                modoEdicao = !modoEdicao;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(modoEdicao
                      ? 'Modo edição ativado. Toque em um card para editar.'
                      : 'Modo edição desativado.'),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: 'Excluir Sala',
            onTap: () {
              // lógica de exclusão (opcional)
            },
          ),
        ],
      ),
    );
  }
}
