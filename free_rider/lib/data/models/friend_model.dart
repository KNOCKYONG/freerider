class Friend {
  final String userId;
  final String nickname;
  final String? profileImageUrl;
  final int todayPoints;
  final int totalPoints;
  final int? ranking;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final bool isOnline;

  Friend({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.todayPoints,
    required this.totalPoints,
    this.ranking,
    required this.joinedAt,
    this.lastActiveAt,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'todayPoints': todayPoints,
      'totalPoints': totalPoints,
      'ranking': ranking,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['userId'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      todayPoints: json['todayPoints'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      ranking: json['ranking'],
      joinedAt: DateTime.parse(json['joinedAt']),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String nickname;
  final String? profileImageUrl;
  final int points;
  final int activities;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.points,
    required this.activities,
    required this.rank,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'points': points,
      'activities': activities,
      'rank': rank,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      points: json['points'] ?? 0,
      activities: json['activities'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}

class InviteRecord {
  final String id;
  final String inviteCode;
  final String invitedUserId;
  final String invitedNickname;
  final DateTime invitedAt;
  final int bonusPoints;
  final bool firstChargeCompleted;

  InviteRecord({
    required this.id,
    required this.inviteCode,
    required this.invitedUserId,
    required this.invitedNickname,
    required this.invitedAt,
    required this.bonusPoints,
    this.firstChargeCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviteCode': inviteCode,
      'invitedUserId': invitedUserId,
      'invitedNickname': invitedNickname,
      'invitedAt': invitedAt.toIso8601String(),
      'bonusPoints': bonusPoints,
      'firstChargeCompleted': firstChargeCompleted,
    };
  }

  factory InviteRecord.fromJson(Map<String, dynamic> json) {
    return InviteRecord(
      id: json['id'],
      inviteCode: json['inviteCode'],
      invitedUserId: json['invitedUserId'],
      invitedNickname: json['invitedNickname'],
      invitedAt: DateTime.parse(json['invitedAt']),
      bonusPoints: json['bonusPoints'] ?? 0,
      firstChargeCompleted: json['firstChargeCompleted'] ?? false,
    );
  }
}