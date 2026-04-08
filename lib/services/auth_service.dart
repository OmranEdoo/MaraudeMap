import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'supabase_bootstrap.dart';

class AuthService {
  const AuthService._();

  static const AuthService instance = AuthService._();

  bool get isConfigured =>
      SupabaseConfig.isConfigured && SupabaseBootstrap.isInitialized;

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => isConfigured ? _client.auth.currentUser : null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      throw AuthException(
        'Supabase n\'est pas encore configure pour cette application.',
      );
    }

    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!isConfigured) {
      return;
    }

    await _client.auth.signOut();
  }
}
