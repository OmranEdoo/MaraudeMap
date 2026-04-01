class CurrentSession {
  static const String displayName = 'Membre TAYBA';
  static const String email = 'membre@tayba.org';
  static const String associationName = 'TAYBA';

  static bool belongsToCurrentAssociation(String association) {
    return _normalize(association) == _normalize(associationName);
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase();
  }
}
