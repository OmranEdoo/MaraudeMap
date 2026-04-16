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

  Future<MemberProfile?> _createProfileFromCurrentUser() async {
    if (!isConfigured) {
      return null;
    }

    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return null;
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? '').toString().trim();
    final associationName =
        (metadata['association_name'] ?? '').toString().trim();
    final email = (authUser.email ?? '').trim();

    if (email.isEmpty || fullName.isEmpty || associationName.isEmpty) {
      return null;
    }

    final row = await _client
        .from('profiles')
        .upsert({
          'id': authUser.id,
          'email': email,
          'full_name': fullName,
          'association_name': associationName,
        }, onConflict: 'id')
        .select()
        .single();

    return MemberProfile.fromSupabaseMap(Map<String, dynamic>.from(row));
  }

  Future<MemberProfile?> hydrateCurrentSession() async {
    var profile = await fetchCurrentProfile();
    profile ??= await _createProfileFromCurrentUser();

    if (profile == null) {
      CurrentSession.resetToDemo();
      return null;
    }

    CurrentSession.updateFromProfile(profile);
    return profile;
  }

  Future<MemberProfile> updateCurrentProfile({
    required String email,
    required String fullName,
    required String associationName,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedFullName = fullName.trim();
    final normalizedAssociationName = associationName.trim();

    final authUser = isConfigured ? _client.auth.currentUser : null;

    if (authUser == null) {
      final profile = MemberProfile(
        id: CurrentSession.userId ?? 'local-profile',
        email: normalizedEmail,
        fullName: normalizedFullName,
        associationName: normalizedAssociationName,
      );

      CurrentSession.updateFromProfile(profile);
      return profile;
    }

    final currentEmail = (authUser.email ?? '').trim();
    final metadata = <String, dynamic>{
      ...(authUser.userMetadata ?? const <String, dynamic>{}),
      'full_name': normalizedFullName,
      'association_name': normalizedAssociationName,
    };

    await _client.auth.updateUser(
      UserAttributes(
        email: normalizedEmail == currentEmail ? null : normalizedEmail,
        data: metadata,
      ),
    );

    final row = await _client
        .from('profiles')
        .update({
          'email': normalizedEmail,
          'full_name': normalizedFullName,
          'association_name': normalizedAssociationName,
        })
        .eq('id', authUser.id)
        .select()
        .single();

    final profile = MemberProfile.fromSupabaseMap(Map<String, dynamic>.from(row));
    CurrentSession.updateFromProfile(profile);
    return profile;
  }
}
