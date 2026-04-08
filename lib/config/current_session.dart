import '../models/member_profile.dart';

class CurrentSession {
  static const String _demoDisplayName = 'Membre TAYBA';
  static const String _demoEmail = 'membre@tayba.org';
  static const String _demoAssociationName = 'TAYBA';

  static String _displayName = _demoDisplayName;
  static String _email = _demoEmail;
  static String _associationName = _demoAssociationName;
  static String? _userId;
  static bool _isDemo = true;

  static String get displayName => _displayName;
  static String get email => _email;
  static String get associationName => _associationName;
  static String? get userId => _userId;
  static bool get isDemo => _isDemo;

  static void updateFromProfile(MemberProfile profile) {
    _userId = profile.id;
    _displayName = profile.fullName.trim().isEmpty
        ? _demoDisplayName
        : profile.fullName;
    _email = profile.email.trim().isEmpty ? _demoEmail : profile.email;
    _associationName = profile.associationName.trim().isEmpty
        ? _demoAssociationName
        : profile.associationName;
    _isDemo = false;
  }

  static void resetToDemo() {
    _userId = null;
    _displayName = _demoDisplayName;
    _email = _demoEmail;
    _associationName = _demoAssociationName;
    _isDemo = true;
  }

  static bool belongsToCurrentAssociation(String association) {
    return _normalize(association) == _normalize(associationName);
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase();
  }
}
