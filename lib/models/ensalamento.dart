class Ensalamento {
  final String id;
  final String salaId;
  final String diaDaSemana;
  final String? primeiroCursoId;
  final String? segundoCursoId;
  final DateTime createdAt;

  Ensalamento({
    required this.id,
    required this.salaId,
    required this.diaDaSemana,
    this.primeiroCursoId,
    this.segundoCursoId,
    required this.createdAt,
  });

  factory Ensalamento.fromMap(Map<String, dynamic> map) {
    return Ensalamento(
      id: map['id'],
      salaId: map['sala_id'],
      diaDaSemana: map['dia_da_semana'],
      primeiroCursoId: map['primeiro_curso_id'],
      segundoCursoId: map['segundo_curso_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sala_id': salaId,
      'dia_da_semana': diaDaSemana,
      'primeiro_curso_id': primeiroCursoId,
      'segundo_curso_id': segundoCursoId,
    };
  }
}
