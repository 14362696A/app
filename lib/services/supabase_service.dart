import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Função de login
  Future<dynamic> login(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Função de cadastro
  Future<dynamic> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }
}
