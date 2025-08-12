import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_rider/data/providers/friends_provider.dart';

void main() {
  group('FriendsProvider Tests', () {
    late ProviderContainer container;
    late FriendsNotifier friendsNotifier;

    setUp(() {
      container = ProviderContainer();
      friendsNotifier = container.read(friendsStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태에 초대 코드가 생성되어야 함', () {
      final state = container.read(friendsStateProvider);
      
      expect(state.myInviteCode, isNotEmpty);
      expect(state.myInviteCode.length, 6);
      expect(state.myInviteCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
    });

    test('Mock 친구 데이터가 초기화되어야 함', () {
      final state = container.read(friendsStateProvider);
      
      expect(state.friends, isNotEmpty);
      expect(state.friends.length, 3);
      expect(state.friends[0].nickname, '김프리');
      expect(state.friends[2].ranking, 1);
    });

    test('유효한 초대 코드 입력 시 친구가 추가되어야 함', () async {
      // Given
      const validCode = 'ABC123';
      final initialFriendCount = container.read(friendsStateProvider).friends.length;
      
      // When
      final result = await friendsNotifier.enterInviteCode(validCode);
      final state = container.read(friendsStateProvider);
      
      // Then
      expect(result, true);
      expect(state.friends.length, initialFriendCount + 1);
      expect(state.inviteRecords.length, 1);
      expect(state.totalInviteBonus, 100);
    });

    test('자기 자신의 초대 코드는 사용할 수 없어야 함', () async {
      // Given
      final myCode = container.read(friendsStateProvider).myInviteCode;
      
      // When
      final result = await friendsNotifier.enterInviteCode(myCode);
      
      // Then
      expect(result, false);
    });

    test('중복 초대 코드는 사용할 수 없어야 함', () async {
      // Given
      const code = 'XYZ789';
      await friendsNotifier.enterInviteCode(code);
      
      // When
      final result = await friendsNotifier.enterInviteCode(code);
      
      // Then
      expect(result, false);
    });

    test('최대 초대 수를 확인해야 함', () {
      final state = container.read(friendsStateProvider);
      
      expect(state.maxInvites, 10);
      expect(state.canInviteMore, true);
    });

    test('유효하지 않은 초대 코드는 거부되어야 함', () async {
      // Given
      const invalidCode = 'INVALID';
      
      // When
      final result = await friendsNotifier.enterInviteCode(invalidCode);
      
      // Then
      expect(result, false);
    });

    test('친구 상태 업데이트가 정상 작동해야 함', () {
      // Given
      final friend = container.read(friendsStateProvider).friends[0];
      final originalPoints = friend.todayPoints;
      
      // When
      friendsNotifier.updateFriendStatus(
        friend.userId,
        isOnline: false,
        todayPoints: 2000,
      );
      
      // Then
      final updatedFriend = container.read(friendsStateProvider)
          .friends
          .firstWhere((f) => f.userId == friend.userId);
      
      expect(updatedFriend.isOnline, false);
      expect(updatedFriend.todayPoints, 2000);
      expect(updatedFriend.todayPoints, isNot(originalPoints));
    });

    test('친구 첫 충전 성공 시 추가 보너스가 지급되어야 함', () async {
      // Given
      await friendsNotifier.enterInviteCode('TEST01');
      final inviteRecord = container.read(friendsStateProvider).inviteRecords[0];
      
      // When
      friendsNotifier.onFriendFirstCharge(inviteRecord.invitedUserId);
      final state = container.read(friendsStateProvider);
      
      // Then
      expect(state.totalInviteBonus, 600); // 100 + 500
      expect(
        state.inviteRecords[0].firstChargeCompleted,
        true,
      );
    });

    test('리더보드가 초기화되어야 함', () {
      final state = container.read(friendsStateProvider);
      
      expect(state.dailyLeaderboard, isNotEmpty);
      expect(state.dailyLeaderboard[0].rank, 1);
      expect(state.dailyLeaderboard[0].nickname, '박포인트');
      expect(state.dailyLeaderboard[0].points, 1550);
    });

    test('리더보드 새로고침이 작동해야 함', () async {
      // Given
      expect(container.read(friendsStateProvider).isLoading, false);
      
      // When
      friendsNotifier.refreshLeaderboard();
      
      // 로딩 상태 확인 (비동기 작업이므로 즉시 확인)
      expect(container.read(friendsStateProvider).isLoading, true);
      
      // 완료 대기
      await Future.delayed(const Duration(seconds: 2));
      
      // Then
      expect(container.read(friendsStateProvider).isLoading, false);
    });
  });
}