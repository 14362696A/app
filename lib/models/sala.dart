class Sala {
  final String id; 
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
    required this.id, 
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

  Sala copyWith({
    String? id,
    String? nome,
    String? bloco,
    bool? ativa,
    bool? arCondicionado,
    bool? tv,
    bool? projetor,
    int? cadeiras,
    int? cadeirasPcd,
    int? computadores,
  }) {
    return Sala(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      bloco: bloco ?? this.bloco,
      ativa: ativa ?? this.ativa,
      arCondicionado: arCondicionado ?? this.arCondicionado,
      tv: tv ?? this.tv,
      projetor: projetor ?? this.projetor,
      cadeiras: cadeiras ?? this.cadeiras,
      cadeirasPcd: cadeirasPcd ?? this.cadeirasPcd,
      computadores: computadores ?? this.computadores,
    );
  }

  factory Sala.fromMap(Map<String, dynamic> map) {
    return Sala(
      id: map['id'], 
      nome: map['nome'] ?? '',
      bloco: map['bloco'] ?? '',
      ativa: map['ativa'] ?? false,
      arCondicionado: map['ar_condicionado'] ?? false,
      tv: map['tv'] ?? false,
      projetor: map['projetor'] ?? false,
      cadeiras: map['cadeiras'] is int ? map['cadeiras'] : int.tryParse(map['cadeiras'].toString()) ?? 0,
      cadeirasPcd: map['cadeiras_pcd'] is int ? map['cadeiras_pcd'] : int.tryParse(map['cadeiras_pcd'].toString()) ?? 0,
      computadores: map['computadores'] is int ? map['computadores'] : int.tryParse(map['computadores'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
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
