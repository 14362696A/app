import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ensalamento.dart';

class EnsalamentoRepository {
  final SupabaseClient _client;

  EnsalamentoRepository(this._client);

  /// Cria um novo ensalamento
  Future<void> criar(Ensalamento ensalamento) async {
    final response = await _client
        .from('ensalamentos')
        .insert(ensalamento.toMap());

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  /// Edita um ensalamento existente
  Future<void> editar(String id, Map<String, dynamic> updates) async {
    final response = await _client
        .from('ensalamentos')
        .update(updates)
        .eq('id', id);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  /// Exclui um ensalamento por ID
  Future<void> excluir(String id) async {
    final response = await _client
        .from('ensalamentos')
        .delete()
        .eq('id', id);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  /// Lista todos os ensalamentos
  Future<List<Ensalamento>> listarTodos() async {
    final response = await _client
        .from('ensalamentos')
        .select()
        .order('dia_da_semana', ascending: true);

    final data = response as List;
    return data.map((e) => Ensalamento.fromMap(e)).toList();
  }

  /// Lista ensalamentos com filtros opcionais por dia, turma e semestre
Future<List<Ensalamento>> listarFiltrado({
  String? diaSemana,
  String? turmaId,
  int? semestre,
}) async {
  var query = _client
      .from('ensalamentos')
      .select('*, '
          'primeira_turma:turmas!ensalamentos_primeiro_curso_id_fkey (id, semestre), '
          'segunda_turma:turmas!ensalamentos_segundo_curso_id_fkey (id, semestre)')
      .order('dia_da_semana', ascending: true) as PostgrestFilterBuilder;

  if (diaSemana != null && diaSemana.isNotEmpty) {
    query = query.eq('dia_da_semana', diaSemana);
  }

  if (turmaId != null && turmaId.isNotEmpty) {
    query = query.or('primeiro_curso_id.eq.$turmaId,segundo_curso_id.eq.$turmaId');
  }

  if (semestre != null) {
    query = query.or(
      'primeira_turma.semestre.eq.$semestre,segunda_turma.semestre.eq.$semestre',
    );
  }

  final response = await query;

  return (response as List).map((e) => Ensalamento.fromMap(e)).toList();
}
  /// Busca um ensalamento por ID
  Future<Ensalamento?> buscarPorId(String id) async {
    final response = await _client
        .from('ensalamentos')
        .select()
        .eq('id', id)
        .single();

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    final data = response.data;
    if (data == null) return null;
    return Ensalamento.fromMap(data);
  }
}
