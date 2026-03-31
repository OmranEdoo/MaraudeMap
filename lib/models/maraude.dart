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
    required this.latitude,
    required this.longitude,
    required this.status,
  });
}

enum MaraudeStatus { planned, ongoing, completed }

enum ZoneStatus { green, orange, red }
