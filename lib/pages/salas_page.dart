import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/sala.dart';
import '../repositories/sala_repository.dart';
import 'package:uuid/uuid.dart';

class SalasPage extends StatefulWidget {
  const SalasPage({super.key});

  @override
  State<SalasPage> createState() => _SalasPageState();
}

class _SalasPageState extends State<SalasPage> {
  final Uuid uuid = Uuid();
  final SalaRepository salaRepository = SalaRepository();
  Map<String, List<Sala>> salasPorCategoria = {};
  String filtroSelecionado = '';
  bool modoEdicao = true;
  bool modoExclusao = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarSalas();
  }

void carregarSalas() async {
  setState(() => isLoading = true);
  final salas = await salaRepository.fetchSalas();

  final Map<String, List<Sala>> agrupadas = {};
  for (var sala in salas) {
    agrupadas.putIfAbsent(sala.bloco, () => []);
    agrupadas[sala.bloco]!.add(sala);
  }

  // Função para extrair o número do nome da sala
  int extrairNumero(String s) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(s);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  // Ordena as salas dentro de cada bloco de forma natural
  agrupadas.forEach((bloco, listaSalas) {
    listaSalas.sort((a, b) {
      final numA = extrairNumero(a.nome);
      final numB = extrairNumero(b.nome);
      if (numA != numB) {
        return numA.compareTo(numB);
      } else {
        // Se os números forem iguais, ordena alfabeticamente pelo restante do nome
        return a.nome.compareTo(b.nome);
      }
    });
  });

  setState(() {
    salasPorCategoria = agrupadas;
    filtroSelecionado = agrupadas.keys.isNotEmpty ? agrupadas.keys.first : '';
    isLoading = false;
    modoEdicao = false;
    modoExclusao = false;
  });
}

  void abrirFormularioEdicao(Sala sala) {
    final formKey = GlobalKey<FormState>();
    bool ativa = sala.ativa;
    bool arCondicionado = sala.arCondicionado;
    bool tv = sala.tv;
    bool projetor = sala.projetor;

    final cadeirasCtrl = TextEditingController(text: sala.cadeiras.toString());
    final cadeirasPcdCtrl = TextEditingController(text: sala.cadeirasPcd.toString());
    final pcsCtrl = TextEditingController(text: sala.computadores.toString());

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
                  onChanged: (v) => setState(() => ativa = v ?? true),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Ativa')),
                    DropdownMenuItem(value: false, child: Text('Inativa')),
                  ],
                  decoration: const InputDecoration(labelText: 'Sala'),
                ),
                DropdownButtonFormField<bool>(
                  value: arCondicionado,
                  onChanged: (v) => setState(() => arCondicionado = v ?? false),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Ar: Sim')),
                    DropdownMenuItem(value: false, child: Text('Ar: Não')),
                  ],
                  decoration: const InputDecoration(labelText: 'Ar-condicionado'),
                ),
                DropdownButtonFormField<bool>(
                  value: tv,
                  onChanged: (v) => setState(() => tv = v ?? false),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('TV: Sim')),
                    DropdownMenuItem(value: false, child: Text('TV: Não')),
                  ],
                  decoration: const InputDecoration(labelText: 'TV'),
                ),
                DropdownButtonFormField<bool>(
                  value: projetor,
                  onChanged: (v) => setState(() => projetor = v ?? false),
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
              final salaEditada = sala.copyWith(
                ativa: ativa,
                arCondicionado: arCondicionado,
                tv: tv,
                projetor: projetor,
                cadeiras: int.tryParse(cadeirasCtrl.text) ?? 0,
                cadeirasPcd: int.tryParse(cadeirasPcdCtrl.text) ?? 0,
                computadores: int.tryParse(pcsCtrl.text) ?? 0,
              );

              await salaRepository.salvarSala(salaEditada);
              Navigator.pop(context);
              carregarSalas();
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

  void abrirFormularioCriacao() {
    final formKey = GlobalKey<FormState>();
    bool ativa = true;
    bool arCondicionado = false;
    bool tv = false;
    bool projetor = false;

    final nomeCtrl = TextEditingController();
    final cadeirasCtrl = TextEditingController();
    final cadeirasPcdCtrl = TextEditingController();
    final pcsCtrl = TextEditingController();
    String? blocoSelecionado = 'Bloco C'; // valor inicial


    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Criar nova Sala'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da Sala'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                DropdownButtonFormField<String>(
                  value: blocoSelecionado,
                  onChanged: (v) => blocoSelecionado = v,
                  items: const [
                    DropdownMenuItem(value: 'Bloco C', child: Text('Bloco C')),
                    DropdownMenuItem(value: 'Bloco D', child: Text('Bloco D')),
                    DropdownMenuItem(value: 'Lab. INF.', child: Text('Lab. INF.')),
                    DropdownMenuItem(value: 'Lab Saúde', child: Text('Lab Saúde')),
                  ],
                  decoration: const InputDecoration(labelText: 'Bloco'),
                  validator: (v) => v == null || v.isEmpty ? 'Selecione o bloco' : null,
                ),
                DropdownButtonFormField<bool>(
                  value: ativa,
                  onChanged: (v) => ativa = v ?? true,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Ativa')),
                    DropdownMenuItem(value: false, child: Text('Inativa')),
                  ],
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                DropdownButtonFormField<bool>(
                  value: arCondicionado,
                  onChanged: (v) => arCondicionado = v ?? false,
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
              if (formKey.currentState?.validate() ?? false) {
                final novaSala = Sala(
                  id: uuid.v4(),
                  nome: nomeCtrl.text.trim(),
bloco: blocoSelecionado ?? '',
                  ativa: ativa,
                  arCondicionado: arCondicionado,
                  tv: tv,
                  projetor: projetor,
                  cadeiras: int.tryParse(cadeirasCtrl.text) ?? 0,
                  cadeirasPcd: int.tryParse(cadeirasPcdCtrl.text) ?? 0,
                  computadores: int.tryParse(pcsCtrl.text) ?? 0,
                );

                await salaRepository.salvarSala(novaSala);
                Navigator.pop(context);
                carregarSalas();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sala criada com sucesso')),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void confirmarExclusao(Sala sala) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Excluir ${sala.nome}?'),
        content: const Text('Confirma exclusão da sala?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await salaRepository.excluirSala(sala);
              Navigator.pop(context);
              carregarSalas();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sala excluída com sucesso')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget buildFiltro() {
    return DropdownButton<String>(
      value: filtroSelecionado.isNotEmpty ? filtroSelecionado : null,
      items: salasPorCategoria.keys.map((key) {
        return DropdownMenuItem(value: key, child: Text(key));
      }).toList(),
      onChanged: (valor) {
        if (valor != null) {
          setState(() {
            filtroSelecionado = valor;
            modoEdicao = false;
            modoExclusao = false;
          });
        }
      },
    );
  }
Widget buildListaSalas() {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  final salas = filtroSelecionado.isNotEmpty
      ? salasPorCategoria[filtroSelecionado] ?? []
      : [];

  if (salas.isEmpty) {
    return const Center(child: Text('Nenhuma sala encontrada.'));
  }

  return GridView.builder(
    padding: const EdgeInsets.all(8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5, // 5 cards por linha
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3 / 2, // Ajusta a proporção do card (largura/altura)
    ),
    itemCount: salas.length,
    itemBuilder: (_, index) {
      final sala = salas[index];
return Card(
  elevation: 3,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            sala.nome,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Status
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sala.ativa ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: sala.ativa ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text('Status: ${sala.ativa ? 'Ativa' : 'Inativa'}'),
          ],
        ),
        const SizedBox(height: 8),

        // Cadeiras, Cadeiras PCD e PCs
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_seat, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Cadeiras: ${sala.cadeiras}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.accessible, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Cadeiras PCD: ${sala.cadeirasPcd}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.computer, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('PCs: ${sala.computadores}'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Equipamentos lado a lado
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sala.arCondicionado ? Icons.ac_unit : Icons.ac_unit_outlined,
                  size: 18,
                  color: sala.arCondicionado ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                const Text('Ar-condicionado'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sala.tv ? Icons.tv : Icons.tv_outlined,
                  size: 18,
                  color: sala.tv ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                const Text('TV'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sala.projetor ? Icons.videocam : Icons.videocam_off,
                  size: 18,
                  color: sala.projetor ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                const Text('Projetor'),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Botões de editar e excluir SEM condições, sempre visíveis
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => abrirFormularioEdicao(sala),
              tooltip: 'Editar',
              iconSize: 24,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => confirmarExclusao(sala),
              tooltip: 'Excluir',
              iconSize: 24,
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
        label: 'Criar Sala',
        onTap: abrirFormularioCriacao,
      ),
      SpeedDialChild(
        child: const Icon(Icons.refresh),
        label: 'Atualizar',
        onTap: carregarSalas,
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas'),
        actions: [buildFiltro()],
      ),
      body: buildListaSalas(),
      floatingActionButton: buildSpeedDial(),
    );
  }
}
