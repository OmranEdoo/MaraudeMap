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

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String associationName,
  }) async {
    if (!isConfigured) {
      throw AuthException(
        'Supabase n\'est pas encore configure pour cette application.',
      );
    }

    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.emailRedirectTo,
      data: {
        'full_name': fullName,
        'association_name': associationName,
      },
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    if (!isConfigured) {
      throw AuthException(
        'Supabase n\'est pas encore configure pour cette application.',
      );
    }

    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.emailRedirectTo,
    );
  }

  Future<void> signOut() async {
    if (!isConfigured) {
      return;
    }

    await _client.auth.signOut();
  }
}
