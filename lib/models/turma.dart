class Turma {
  final String id;
  final String nomeDoCurso;
  final String turno;
  final int semestre;
  final int qtdDeAlunos;
  final String observacoes;

  Turma({
    required this.id,
    required this.nomeDoCurso,
    required this.turno,
    required this.semestre,
    required this.qtdDeAlunos,
    required this.observacoes,
  });

  Turma copyWith({
    String? id,
    String? nomeDoCurso,
    String? turno,
    int? semestre,
    int? qtdDeAlunos,
    String? observacoes,
  }) {
    return Turma(
      id: id ?? this.id,
      nomeDoCurso: nomeDoCurso ?? this.nomeDoCurso,
      turno: turno ?? this.turno,
      semestre: semestre ?? this.semestre,
      qtdDeAlunos: qtdDeAlunos ?? this.qtdDeAlunos,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  factory Turma.fromMap(Map<String, dynamic> map) {
    return Turma(
      id: map['id'] ?? '',
      nomeDoCurso: map['nomeDoCurso'] ?? '',
      turno: map['turno'] ?? '',
      semestre: map['semestre'] is int
          ? map['semestre']
          : int.tryParse(map['semestre'].toString()) ?? 0,
      qtdDeAlunos: map['qtdDeAlunos'] is int
          ? map['qtdDeAlunos']
          : int.tryParse(map['qtdDeAlunos'].toString()) ?? 0,
      observacoes: map['observacoes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeDoCurso': nomeDoCurso,
      'turno': turno,
      'semestre': semestre,
      'qtdDeAlunos': qtdDeAlunos,
      'observacoes': observacoes,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Turma &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
