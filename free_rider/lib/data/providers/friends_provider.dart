import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../models/friend_model.dart';

// Friends State Provider
final friendsStateProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});

class FriendsState {
  final List<Friend> friends;
  final List<InviteRecord> inviteRecords;
  final String myInviteCode;
  final int totalInviteBonus;
  final List<LeaderboardEntry> dailyLeaderboard;
  final List<LeaderboardEntry> weeklyLeaderboard;
  final List<LeaderboardEntry> monthlyLeaderboard;
  final bool isLoading;

  FriendsState({
    this.friends = const [],
    this.inviteRecords = const [],
    required this.myInviteCode,
    this.totalInviteBonus = 0,
    this.dailyLeaderboard = const [],
    this.weeklyLeaderboard = const [],
    this.monthlyLeaderboard = const [],
    this.isLoading = false,
  });

  FriendsState copyWith({
    List<Friend>? friends,
    List<InviteRecord>? inviteRecords,
    String? myInviteCode,
    int? totalInviteBonus,
    List<LeaderboardEntry>? dailyLeaderboard,
    List<LeaderboardEntry>? weeklyLeaderboard,
    List<LeaderboardEntry>? monthlyLeaderboard,
    bool? isLoading,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      inviteRecords: inviteRecords ?? this.inviteRecords,
      myInviteCode: myInviteCode ?? this.myInviteCode,
      totalInviteBonus: totalInviteBonus ?? this.totalInviteBonus,
      dailyLeaderboard: dailyLeaderboard ?? this.dailyLeaderboard,
      weeklyLeaderboard: weeklyLeaderboard ?? this.weeklyLeaderboard,
      monthlyLeaderboard: monthlyLeaderboard ?? this.monthlyLeaderboard,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get invitedCount => inviteRecords.length;
  int get maxInvites => 10;
  bool get canInviteMore => invitedCount < maxInvites;
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier() : super(FriendsState(
    myInviteCode: _generateInviteCode(),
  )) {
    _initializeMockData();
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _initializeMockData() {
    // Mock friends
    final mockFriends = [
      Friend(
        userId: 'friend_001',
        nickname: '김프리',
        todayPoints: 1230,
        totalPoints: 45600,
        ranking: 2,
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isOnline: true,
      ),
      Friend(
        userId: 'friend_002',
        nickname: '이라이더',
        todayPoints: 980,
        totalPoints: 38900,
        ranking: 5,
        joinedAt: DateTime.now().subtract(const Duration(days: 20)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 1)),
        isOnline: true,
      ),
      Friend(
        userId: 'friend_003',
        nickname: '박포인트',
        todayPoints: 1550,
        totalPoints: 52300,
        ranking: 1,
        joinedAt: DateTime.now().subtract(const Duration(days: 45)),
        lastActiveAt: DateTime.now().subtract(const Duration(days: 1)),
        isOnline: false,
      ),
    ];

    // Mock leaderboard
    final mockDailyLeaderboard = [
      LeaderboardEntry(
        userId: 'friend_003',
        nickname: '박포인트',
        points: 1550,
        activities: 15,
        rank: 1,
      ),
      LeaderboardEntry(
        userId: 'friend_001',
        nickname: '김프리',
        points: 1230,
        activities: 12,
        rank: 2,
      ),
      LeaderboardEntry(
        userId: 'current_user',
        nickname: '나',
        points: 1100,
        activities: 10,
        rank: 3,
      ),
      LeaderboardEntry(
        userId: 'user_004',
        nickname: '최워커',
        points: 1050,
        activities: 11,
        rank: 4,
      ),
      LeaderboardEntry(
        userId: 'friend_002',
        nickname: '이라이더',
        points: 980,
        activities: 9,
        rank: 5,
      ),
    ];

    state = state.copyWith(
      friends: mockFriends,
      dailyLeaderboard: mockDailyLeaderboard,
      weeklyLeaderboard: mockDailyLeaderboard, // 실제로는 다른 데이터
      monthlyLeaderboard: mockDailyLeaderboard, // 실제로는 다른 데이터
    );
  }

  Future<bool> enterInviteCode(String code) async {
    // 이미 사용된 코드인지 확인
    if (state.inviteRecords.any((record) => record.inviteCode == code)) {
      return false;
    }

    // 자기 자신의 코드인지 확인
    if (code == state.myInviteCode) {
      return false;
    }

    // 최대 초대 횟수 확인
    if (!state.canInviteMore) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      // 시뮬레이션: 서버 확인
      await Future.delayed(const Duration(seconds: 1));

      // Mock 유효한 코드들
      final validCodes = ['ABC123', 'XYZ789', 'TEST01', 'DEMO99'];
      if (!validCodes.contains(code) && !code.startsWith('FR')) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // 초대 기록 추가
      final inviteRecord = InviteRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inviteCode: code,
        invitedUserId: 'new_friend_${state.inviteRecords.length + 1}',
        invitedNickname: '친구${state.inviteRecords.length + 1}',
        invitedAt: DateTime.now(),
        bonusPoints: 100,
      );

      // 친구 추가
      final newFriend = Friend(
        userId: inviteRecord.invitedUserId,
        nickname: inviteRecord.invitedNickname,
        todayPoints: 0,
        totalPoints: 100,
        joinedAt: DateTime.now(),
        isOnline: true,
      );

      state = state.copyWith(
        inviteRecords: [...state.inviteRecords, inviteRecord],
        friends: [...state.friends, newFriend],
        totalInviteBonus: state.totalInviteBonus + 100,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  void updateFriendStatus(String userId, {bool? isOnline, int? todayPoints}) {
    final updatedFriends = state.friends.map((friend) {
      if (friend.userId == userId) {
        return Friend(
          userId: friend.userId,
          nickname: friend.nickname,
          profileImageUrl: friend.profileImageUrl,
          todayPoints: todayPoints ?? friend.todayPoints,
          totalPoints: friend.totalPoints,
          ranking: friend.ranking,
          joinedAt: friend.joinedAt,
          lastActiveAt: isOnline != null ? DateTime.now() : friend.lastActiveAt,
          isOnline: isOnline ?? friend.isOnline,
        );
      }
      return friend;
    }).toList();

    state = state.copyWith(friends: updatedFriends);
  }

  void refreshLeaderboard() async {
    state = state.copyWith(isLoading: true);
    
    // 시뮬레이션: 서버에서 리더보드 데이터 가져오기
    await Future.delayed(const Duration(seconds: 1));
    
    // 여기서는 기존 데이터 유지
    state = state.copyWith(isLoading: false);
  }

  void onFriendFirstCharge(String invitedUserId) {
    // 친구가 첫 충전 성공 시 500P 추가 보너스
    final updatedRecords = state.inviteRecords.map((record) {
      if (record.invitedUserId == invitedUserId && !record.firstChargeCompleted) {
        return InviteRecord(
          id: record.id,
          inviteCode: record.inviteCode,
          invitedUserId: record.invitedUserId,
          invitedNickname: record.invitedNickname,
          invitedAt: record.invitedAt,
          bonusPoints: record.bonusPoints + 500,
          firstChargeCompleted: true,
        );
      }
      return record;
    }).toList();

    state = state.copyWith(
      inviteRecords: updatedRecords,
      totalInviteBonus: state.totalInviteBonus + 500,
    );
  }
}