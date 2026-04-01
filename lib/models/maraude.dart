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
}

enum MaraudeStatus { planned, ongoing, completed }

enum ZoneStatus { green, orange, red }
