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
  bool modoEdicao = false;
  bool modoExclusao = false;
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
    final blocoCtrl = TextEditingController();
    final cadeirasCtrl = TextEditingController();
    final cadeirasPcdCtrl = TextEditingController();
    final pcsCtrl = TextEditingController();

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
                TextFormField(
                  controller: blocoCtrl,
                  decoration: const InputDecoration(labelText: 'Bloco'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o bloco' : null,
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
                  bloco: blocoCtrl.text.trim(),
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

    return ListView.builder(
      itemCount: salas.length,
      itemBuilder: (_, index) {
        final sala = salas[index];
        return Card(
          child: ListTile(
            title: Text(sala.nome),
            subtitle: Text('Cadeiras: ${sala.cadeiras}, PCD: ${sala.cadeirasPcd}, PCs: ${sala.computadores}'),
            trailing: modoExclusao
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => confirmarExclusao(sala),
                  )
                : modoEdicao
                    ? IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => abrirFormularioEdicao(sala),
                      )
                    : null,
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
          child: const Icon(Icons.edit),
          label: modoEdicao ? 'Cancelar Edição' : 'Modo Edição',
          onTap: () {
            setState(() {
              modoEdicao = !modoEdicao;
              if (modoEdicao) modoExclusao = false;
            });
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.delete),
          label: modoExclusao ? 'Cancelar Exclusão' : 'Modo Exclusão',
          onTap: () {
            setState(() {
              modoExclusao = !modoExclusao;
              if (modoExclusao) modoEdicao = false;
            });
          },
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
