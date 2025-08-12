import 'package:geolocator/geolocator.dart';

enum ActivityType {
  walking,
  stairs,
  cycling,
  transit,
  running,
  meditation,
  voiceDiary,
  phoneCall,
  adWatching,
  survey,
  qrScan,
  quiz,
  newsReading,
}

class DailyActivity {
  final ActivityType type;
  final int value; // steps, floors, minutes, count
  final int points;
  final DateTime timestamp;

  DailyActivity({
    required this.type,
    required this.value,
    required this.points,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'value': value,
      'points': points,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      value: json['value'],
      points: json['points'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class TransitStatus {
  final DateTime startTime;
  final Position startPosition;

  TransitStatus({
    required this.startTime,
    required this.startPosition,
  });
}

class ActivitySummary {
  final String type;
  final String displayValue;
  final int points;
  final double progress; // 0.0 to 1.0
  final int maxPoints;

  ActivitySummary({
    required this.type,
    required this.displayValue,
    required this.points,
    required this.progress,
    required this.maxPoints,
  });
}