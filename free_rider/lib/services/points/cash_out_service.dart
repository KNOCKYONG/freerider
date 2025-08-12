import 'dart:async';
import 'package:flutter/foundation.dart';

/// 포인트 현금화 서비스
/// 교통카드 직접 충전 대신 포인트를 현금으로 전환
class CashOutService {
  static final CashOutService _instance = CashOutService._internal();
  factory CashOutService() => _instance;
  CashOutService._internal();

  // 최소 현금화 포인트
  static const int minimumCashOutPoints = 1550; // 서울 지하철 기본요금
  
  // 현금화 수수료 (%)
  static const double cashOutFeeRate = 0.0; // 무료 (수익은 광고에서)
  
  // 일일 현금화 한도
  static const int dailyCashOutLimit = 10000; // 10,000원
  
  // 월간 현금화 한도
  static const int monthlyCashOutLimit = 300000; // 30만원

  // 현금화 기록
  final List<CashOutRecord> _cashOutHistory = [];
  int _dailyCashOutAmount = 0;
  int _monthlyCashOutAmount = 0;
  DateTime _lastResetDate = DateTime.now();

  /// 포인트 현금화 요청
  Future<CashOutResult> requestCashOut({
    required String userId,
    required int points,
    required BankAccount bankAccount,
    String? memo,
  }) async {
    try {
      // 유효성 검증
      final validation = _validateCashOut(points);
      if (!validation.isValid) {
        return CashOutResult(
          success: false,
          errorMessage: validation.message,
        );
      }

      // 수수료 계산
      final fee = (points * cashOutFeeRate).toInt();
      final actualAmount = points - fee;

      // Mock API 호출 (실제로는 은행 API 연동)
      await Future.delayed(const Duration(seconds: 2));

      // 현금화 기록 생성
      final record = CashOutRecord(
        id: 'CO_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        points: points,
        amount: actualAmount,
        fee: fee,
        bankAccount: bankAccount,
        status: CashOutStatus.pending,
        requestedAt: DateTime.now(),
        memo: memo,
      );

      _cashOutHistory.add(record);
      _updateDailyAndMonthlyAmounts(actualAmount);

      // 2-3일 후 완료 처리 (Mock)
      Timer(const Duration(seconds: 5), () {
        record.status = CashOutStatus.completed;
        record.completedAt = DateTime.now();
      });

      return CashOutResult(
        success: true,
        cashOutId: record.id,
        expectedAmount: actualAmount,
        expectedDate: DateTime.now().add(const Duration(days: 2)),
      );
    } catch (e) {
      return CashOutResult(
        success: false,
        errorMessage: '현금화 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 현금화 가능 여부 확인
  CashOutValidation _validateCashOut(int points) {
    _resetDailyAndMonthlyLimits();

    if (points < minimumCashOutPoints) {
      return CashOutValidation(
        isValid: false,
        message: '최소 ${minimumCashOutPoints}P 이상부터 현금화 가능합니다',
      );
    }

    if (_dailyCashOutAmount + points > dailyCashOutLimit) {
      final remaining = dailyCashOutLimit - _dailyCashOutAmount;
      return CashOutValidation(
        isValid: false,
        message: '일일 한도 초과. 오늘 ${remaining}P까지 가능합니다',
      );
    }

    if (_monthlyCashOutAmount + points > monthlyCashOutLimit) {
      final remaining = monthlyCashOutLimit - _monthlyCashOutAmount;
      return CashOutValidation(
        isValid: false,
        message: '월간 한도 초과. 이번 달 ${remaining}P까지 가능합니다',
      );
    }

    return CashOutValidation(isValid: true);
  }

  /// 일일/월간 한도 리셋
  void _resetDailyAndMonthlyLimits() {
    final now = DateTime.now();
    
    // 일일 리셋
    if (now.day != _lastResetDate.day) {
      _dailyCashOutAmount = 0;
    }
    
    // 월간 리셋
    if (now.month != _lastResetDate.month) {
      _monthlyCashOutAmount = 0;
    }
    
    _lastResetDate = now;
  }

  /// 일일/월간 사용량 업데이트
  void _updateDailyAndMonthlyAmounts(int amount) {
    _dailyCashOutAmount += amount;
    _monthlyCashOutAmount += amount;
  }

  /// 현금화 내역 조회
  List<CashOutRecord> getCashOutHistory(String userId) {
    return _cashOutHistory
        .where((record) => record.userId == userId)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  /// 현금화 상태 조회
  CashOutRecord? getCashOutStatus(String cashOutId) {
    try {
      return _cashOutHistory.firstWhere((record) => record.id == cashOutId);
    } catch (e) {
      return null;
    }
  }

  /// 예상 도착 시간 계산
  DateTime calculateExpectedArrival() {
    final now = DateTime.now();
    
    // 평일 오전 11시 이전 신청: 당일 처리
    // 그 외: 익영업일 처리
    if (now.weekday <= 5 && now.hour < 11) {
      return now;
    } else if (now.weekday == 5 && now.hour >= 11) {
      // 금요일 오후 -> 월요일
      return now.add(const Duration(days: 3));
    } else if (now.weekday == 6) {
      // 토요일 -> 월요일
      return now.add(const Duration(days: 2));
    } else if (now.weekday == 7) {
      // 일요일 -> 월요일
      return now.add(const Duration(days: 1));
    } else {
      // 평일 -> 익일
      return now.add(const Duration(days: 1));
    }
  }

  /// 남은 일일 한도
  int getRemainingDailyLimit() {
    _resetDailyAndMonthlyLimits();
    return dailyCashOutLimit - _dailyCashOutAmount;
  }

  /// 남은 월간 한도
  int getRemainingMonthlyLimit() {
    _resetDailyAndMonthlyLimits();
    return monthlyCashOutLimit - _monthlyCashOutAmount;
  }

  /// 은행 계좌 검증
  Future<bool> verifyBankAccount(BankAccount account) async {
    // Mock 검증 (실제로는 은행 API 호출)
    await Future.delayed(const Duration(seconds: 1));
    
    // 계좌번호 형식 검증
    if (account.accountNumber.length < 10) {
      return false;
    }
    
    // 예금주명 검증
    if (account.accountHolder.isEmpty) {
      return false;
    }
    
    return true;
  }

  /// 1원 인증
  Future<OneWonVerification> requestOneWonVerification(BankAccount account) async {
    // Mock 1원 송금 (실제로는 은행 API)
    await Future.delayed(const Duration(seconds: 2));
    
    final verificationCode = '${DateTime.now().millisecond}'.padLeft(4, '0');
    
    return OneWonVerification(
      accountNumber: account.accountNumber,
      bankCode: account.bankCode,
      verificationCode: verificationCode,
      expiresAt: DateTime.now().add(const Duration(minutes: 3)),
    );
  }

  /// 1원 인증 확인
  Future<bool> verifyOneWon(String accountNumber, String inputCode, String actualCode) async {
    return inputCode == actualCode;
  }
}

/// 현금화 요청 결과
class CashOutResult {
  final bool success;
  final String? cashOutId;
  final int? expectedAmount;
  final DateTime? expectedDate;
  final String? errorMessage;

  CashOutResult({
    required this.success,
    this.cashOutId,
    this.expectedAmount,
    this.expectedDate,
    this.errorMessage,
  });
}

/// 현금화 유효성 검증 결과
class CashOutValidation {
  final bool isValid;
  final String? message;

  CashOutValidation({
    required this.isValid,
    this.message,
  });
}

/// 현금화 기록
class CashOutRecord {
  final String id;
  final String userId;
  final int points;
  final int amount;
  final int fee;
  final BankAccount bankAccount;
  CashOutStatus status;
  final DateTime requestedAt;
  DateTime? completedAt;
  final String? memo;
  String? transactionId;

  CashOutRecord({
    required this.id,
    required this.userId,
    required this.points,
    required this.amount,
    required this.fee,
    required this.bankAccount,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.memo,
    this.transactionId,
  });
}

/// 현금화 상태
enum CashOutStatus {
  pending,    // 처리 중
  processing, // 이체 진행 중
  completed,  // 완료
  failed,     // 실패
  cancelled,  // 취소
}

/// 은행 계좌 정보
class BankAccount {
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final bool isVerified;
  final DateTime? verifiedAt;

  BankAccount({
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.isVerified = false,
    this.verifiedAt,
  });

  Map<String, dynamic> toJson() => {
    'bankCode': bankCode,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'accountHolder': accountHolder,
    'isVerified': isVerified,
    'verifiedAt': verifiedAt?.toIso8601String(),
  };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    bankCode: json['bankCode'],
    bankName: json['bankName'],
    accountNumber: json['accountNumber'],
    accountHolder: json['accountHolder'],
    isVerified: json['isVerified'] ?? false,
    verifiedAt: json['verifiedAt'] != null 
        ? DateTime.parse(json['verifiedAt'])
        : null,
  );
}

/// 1원 인증 정보
class OneWonVerification {
  final String accountNumber;
  final String bankCode;
  final String verificationCode;
  final DateTime expiresAt;

  OneWonVerification({
    required this.accountNumber,
    required this.bankCode,
    required this.verificationCode,
    required this.expiresAt,
  });
}

/// 지원 은행 목록
class SupportedBanks {
  static const Map<String, String> banks = {
    '004': 'KB국민은행',
    '088': '신한은행',
    '020': '우리은행',
    '081': '하나은행',
    '011': 'NH농협은행',
    '090': '카카오뱅크',
    '092': '토스뱅크',
    '003': 'IBK기업은행',
    '023': 'SC제일은행',
    '027': '씨티은행',
    '032': '부산은행',
    '034': '광주은행',
    '035': '제주은행',
    '037': '전북은행',
    '039': '경남은행',
  };
}