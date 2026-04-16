import 'package:flutter/foundation.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _mobileEmailRedirectUrl =
      'maraudemap://login-callback/';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static String? get emailRedirectTo =>
      kIsWeb ? null : _mobileEmailRedirectUrl;
}
