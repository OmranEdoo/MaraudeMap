class Maraude {
  final String id;
  final String associationName;
  final String location;
  final String address;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int estimatedPlates;
  final String distributionType;
  final String comment;
  final double latitude;
  final double longitude;
  final MaraudeStatus status;

  Maraude({
    required this.id,
    required this.associationName,
    required this.location,
    required this.address,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.estimatedPlates,
    required this.distributionType,
    this.comment = '',
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  Maraude copyWith({
    String? id,
    String? associationName,
    String? location,
    String? address,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? estimatedPlates,
    String? distributionType,
    String? comment,
    double? latitude,
    double? longitude,
    MaraudeStatus? status,
  }) {
    final currentComment = () {
      try {
        return this.comment;
      } catch (_) {
        return '';
      }
    }();

    return Maraude(
      id: id ?? this.id,
      associationName: associationName ?? this.associationName,
      location: location ?? this.location,
      address: address ?? this.address,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      estimatedPlates: estimatedPlates ?? this.estimatedPlates,
      distributionType: distributionType ?? this.distributionType,
      comment: comment ?? currentComment,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }

  factory Maraude.fromSupabaseMap(Map<String, dynamic> map) {
    return Maraude(
      id: (map['id'] ?? '').toString(),
      associationName: (map['association_name'] ?? '').toString(),
      location: _stringValue(map['location']).isNotEmpty
          ? _stringValue(map['location'])
          : _deriveLocation(_stringValue(map['address'])),
      address: _stringValue(map['address']),
      date: _parseDatabaseDate(map['date']),
      startTime: _normalizeDatabaseTime(map['start_time']),
      endTime: _normalizeDatabaseTime(map['end_time']),
      estimatedPlates: _intValue(map['estimated_plates']),
      distributionType: _stringValue(map['distribution_type']).isNotEmpty
          ? _stringValue(map['distribution_type'])
          : 'Standard',
      comment: _stringValue(map['comment']),
      latitude: _doubleValue(map['latitude']),
      longitude: _doubleValue(map['longitude']),
      status: _statusFromValue(map['status']),
    );
  }

  Map<String, dynamic> toSupabaseWriteMap({
    String? createdBy,
    bool includeId = true,
  }) {
    final map = <String, dynamic>{
      'association_name': associationName,
      'location': location,
      'address': address,
      'date': formatDatabaseDate(date),
      'start_time': _databaseTimeValue(startTime),
      'end_time': _databaseTimeValue(endTime),
      'estimated_plates': estimatedPlates,
      'distribution_type':
          distributionType.trim().isEmpty ? 'Standard' : distributionType,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
    };

    if (createdBy != null && createdBy.isNotEmpty) {
      map['created_by'] = createdBy;
    }

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }

  static String formatDatabaseDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final month = normalizedDate.month.toString().padLeft(2, '0');
    final day = normalizedDate.day.toString().padLeft(2, '0');
    return '${normalizedDate.year}-$month-$day';
  }

  static DateTime _parseDatabaseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static String _normalizeDatabaseTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(raw);
    if (match == null) {
      return raw;
    }

    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    if (minute == 0) {
      return '${hour}h';
    }

    return '${hour}h${minute.toString().padLeft(2, '0')}';
  }

  static String _databaseTimeValue(String value) {
    final normalized = value.trim().toLowerCase();
    final match =
        RegExp(r'^(\d{1,2})(?:h|:)?(\d{0,2})(?::\d{0,2})?$').firstMatch(normalized);
    if (match == null) {
      return value;
    }

    final hour = (int.tryParse(match.group(1) ?? '') ?? 0).clamp(0, 23);
    final minuteGroup = match.group(2) ?? '';
    final minute = minuteGroup.isEmpty
        ? 0
        : (int.tryParse(minuteGroup) ?? 0).clamp(0, 59);

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  static String _deriveLocation(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.split(',').first.trim();
  }

  static String _stringValue(dynamic value) {
    return value?.toString() ?? '';
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleValue(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static MaraudeStatus _statusFromValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'completed':
        return MaraudeStatus.completed;
      case 'ongoing':
        return MaraudeStatus.ongoing;
      case 'planned':
      default:
        return MaraudeStatus.planned;
    }
  }
}

enum MaraudeStatus { planned, ongoing, completed }

enum ZoneStatus { green, orange, red }
