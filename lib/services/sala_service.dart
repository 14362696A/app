import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class Sala {
  final String nome;
  final String bloco;
  final bool ativa;
  final bool arCondicionado;
  final bool tv;
  final bool projetor;
  final int cadeiras;
  final int cadeirasPcd;
  final int computadores;

  Sala({
    required this.nome,
    required this.bloco,
    required this.ativa,
    required this.arCondicionado,
    required this.tv,
    required this.projetor,
    required this.cadeiras,
    required this.cadeirasPcd,
    required this.computadores,
  });

  // Método para converter de Map para objeto Sala (caso precise)
  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      nome: json['nome'],
      bloco: json['bloco'],
      ativa: json['ativa'],
      arCondicionado: json['ar_condicionado'],
      tv: json['tv'],
      projetor: json['projetor'],
      cadeiras: json['cadeiras'],
      cadeirasPcd: json['cadeiras_pcd'],
      computadores: json['computadores'],
    );
  }

  // Método para converter de objeto Sala para Map (caso precise para salvar no banco)
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'bloco': bloco,
      'ativa': ativa,
      'ar_condicionado': arCondicionado,
      'tv': tv,
      'projetor': projetor,
      'cadeiras': cadeiras,
      'cadeiras_pcd': cadeirasPcd,
      'computadores': computadores,
    };
  }
}

Future<void> salvarSala({
  required String nome,
  required String bloco,
  required bool ativa,
  required bool ar,
  required bool tv,
  required bool projetor,
  required int cadeiras,
  required int cadeirasPcd,
  required int computadores,
}) async {
  final supabase = Supabase.instance.client;

  // Usando o upsert para salvar ou atualizar a sala
  await supabase.from('salas').upsert({
    'nome': nome,
    'bloco': bloco,
    'ativa': ativa,
    'ar_condicionado': ar,
    'tv': tv,
    'projetor': projetor,
    'cadeiras': cadeiras,
    'cadeiras_pcd': cadeirasPcd,
    'computadores': computadores,
  }).execute();
}

class SalaService {
  Future<void> preencherSalasPredefinidas(BuildContext context) async {
    final response = await Supabase.instance.client
        .from('salas')
        .select()
        .execute();

    if (response.data != null && (response.data as List).isEmpty) {
      final salasPredefinidas = [
        Sala(nome: '1C', bloco: 'Bloco C', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: '2C', bloco: 'Bloco C', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: '3C', bloco: 'Bloco C', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: '1D', bloco: 'Bloco D', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: '2D', bloco: 'Bloco D', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: '3D', bloco: 'Bloco D', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: 'Lab 1', bloco: 'Laboratório', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
        Sala(nome: 'Lab 2', bloco: 'Laboratório', ativa: true, arCondicionado: false, tv: false, projetor: false, cadeiras: 0, cadeirasPcd: 0, computadores: 0),
      ];

      for (var sala in salasPredefinidas) {
        // Insere as salas predefinidas no banco de dados
        await Supabase.instance.client.from('salas').insert([sala.toJson()]).execute();
      }

      // Exibe mensagem de confirmação ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salas predefinidas foram inseridas no banco de dados')),
      );
    }
  }
}
