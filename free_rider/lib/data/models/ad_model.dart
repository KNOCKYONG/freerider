import 'package:flutter/material.dart';

class AdModel {
  final String id;
  final String title;
  final String advertiser;
  final String description;
  final int duration; // in seconds
  final int points;
  final AdType type;
  final String? imageUrl;
  final String? videoUrl;
  final Color color;
  final DateTime? expiresAt;

  AdModel({
    required this.id,
    required this.title,
    required this.advertiser,
    required this.description,
    required this.duration,
    required this.points,
    required this.type,
    this.imageUrl,
    this.videoUrl,
    required this.color,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'advertiser': advertiser,
      'description': description,
      'duration': duration,
      'points': points,
      'type': type.toString(),
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'color': color.value,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'],
      title: json['title'],
      advertiser: json['advertiser'],
      description: json['description'],
      duration: json['duration'],
      points: json['points'],
      type: AdType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AdType.video,
      ),
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      color: Color(json['color']),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }
}

enum AdType {
  video,
  banner,
  interstitial,
  rewarded,
  native,
}

class AdWatchRecord {
  final String adId;
  final DateTime watchedAt;
  final int pointsEarned;
  final bool completed;

  AdWatchRecord({
    required this.adId,
    required this.watchedAt,
    required this.pointsEarned,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'adId': adId,
      'watchedAt': watchedAt.toIso8601String(),
      'pointsEarned': pointsEarned,
      'completed': completed,
    };
  }

  factory AdWatchRecord.fromJson(Map<String, dynamic> json) {
    return AdWatchRecord(
      adId: json['adId'],
      watchedAt: DateTime.parse(json['watchedAt']),
      pointsEarned: json['pointsEarned'],
      completed: json['completed'],
    );
  }
}