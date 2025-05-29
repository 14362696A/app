// turma_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/turma.dart';

class TurmaService {
  final supabase = Supabase.instance.client;

  Future<List<Turma>> getAllTurmas() async {
    try {
      final response = await supabase
          .from('turmas')
          .select('"id", "nomeDoCurso", "turno", "semestre", "qtdDeAlunos", "observacoes"');

      return (response as List).map((json) => Turma.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao buscar turmas: $e');
      return [];
    }
  }
}

