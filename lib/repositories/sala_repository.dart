import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart';

class SalaRepository {
  final supabase = Supabase.instance.client;

  Future<List<Sala>> fetchSalas() async {
    try {
      final response = await supabase.from('salas').select().execute();

      if (response.status != 200 || response.data == null) {
        throw Exception('Erro ao buscar salas: status ${response.status}');
      }

      final data = response.data as List<dynamic>;
      return data.map((item) => Sala.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar salas: $e');
    }
  }

  Future<void> salvarSala(Sala sala) async {
    try {
      final response =
          await supabase.from('salas').upsert(sala.toMap()).execute();

      if (response.status != 200 && response.status != 201) {
        throw Exception('Erro ao salvar sala: status ${response.status}');
      }
    } catch (e) {
      throw Exception('Erro ao salvar sala: $e');
    }
  }

  Future<void> excluirSala(Sala sala) async {
    try {
      final response = await supabase
          .from('salas')
          .delete()
          .match({'id': sala.id})
          .execute();

      if (response.status != 200 && response.status != 204) {
        throw Exception('Erro ao excluir sala: status ${response.status}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir sala: $e');
    }
  }
}
