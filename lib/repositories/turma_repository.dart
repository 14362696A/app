import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/turma.dart';

class TurmaRepository {
  final supabase = Supabase.instance.client;

  Future<List<Turma>> fetchTurmas() async {
    try {
      final response = await supabase
          .from('turmas')
          .select()
          .order('nomeDoCurso', ascending: true)
          .execute();

      if (response.status != 200 || response.data == null) {
        throw Exception('Erro ao buscar turmas: status ${response.status}');
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Turma.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar turmas: $e');
    }
  }

  Future<Turma> salvarTurma(Turma turma) async {
    try {
      // Converter os dados para o formato correto antes de enviar
      final turmaData = {
        'id': turma.id,
        'nomeDoCurso': turma.nomeDoCurso,
        'turno': turma.turno,
        'semestre': turma.semestre,
        'qtdDeAlunos':
            turma.qtdDeAlunos.toString(), // Convertendo int para String
        'observacoes': turma.observacoes,
      };

      final response = await supabase
          .from('turmas')
          .upsert(turmaData)
          .select()
          .single()
          .execute();

      if (response.status != 200 && response.status != 201) {
        throw Exception('Erro ao salvar turma: status ${response.status}');
      }

      return Turma.fromMap(response.data);
    } catch (e) {
      throw Exception('Erro ao salvar turma: $e');
    }
  }

  Future<void> excluirTurma(String id) async {
    try {
      final response =
          await supabase.from('turmas').delete().eq('id', id).execute();

      if (response.status != 200 && response.status != 204) {
        throw Exception('Erro ao excluir turma: status ${response.status}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir turma: $e');
    }
  }
}
