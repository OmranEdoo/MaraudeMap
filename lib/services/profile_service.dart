import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/current_session.dart';
import '../config/supabase_config.dart';
import '../models/member_profile.dart';
import 'supabase_bootstrap.dart';

class ProfileService {
  const ProfileService._();

  static const ProfileService instance = ProfileService._();

  bool get isConfigured =>
      SupabaseConfig.isConfigured && SupabaseBootstrap.isInitialized;

  SupabaseClient get _client => Supabase.instance.client;

  Future<MemberProfile?> fetchCurrentProfile() async {
    if (!isConfigured) {
      return null;
    }

    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return null;
    }

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return MemberProfile.fromSupabaseMap(Map<String, dynamic>.from(row));
  }

  Future<MemberProfile?> hydrateCurrentSession() async {
    final profile = await fetchCurrentProfile();
    if (profile == null) {
      CurrentSession.resetToDemo();
      return null;
    }

    CurrentSession.updateFromProfile(profile);
    return profile;
  }
}
