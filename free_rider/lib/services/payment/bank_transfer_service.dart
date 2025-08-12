import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

/// 계좌 이체 충전 서비스
/// 모바일 페이 사용 불가 시 대체 충전 방법
class BankTransferService {
  static const _platform = MethodChannel('com.freerider.payment/bank_transfer');
  
  // 싱글톤 인스턴스
  static final BankTransferService _instance = BankTransferService._internal();
  factory BankTransferService() => _instance;
  BankTransferService._internal();

  // 지원 은행 목록
  static const Map<String, String> supportedBanks = {
    'KB': 'KB국민은행',
    'SHINHAN': '신한은행',
    'WOORI': '우리은행',
    'HANA': '하나은행',
    'NH': 'NH농협은행',
    'KAKAO': '카카오뱅크',
    'TOSS': '토스뱅크',
    'IBK': 'IBK기업은행',
    'SC': 'SC제일은행',
    'CITI': '씨티은행',
  };

  /// 가상계좌 생성
  Future<VirtualAccount> createVirtualAccount({
    required String userId,
    required int amount,
    required String cardType,
    required String cardNumber,
  }) async {
    try {
      // 가상계좌 생성 요청
      final response = await _platform.invokeMethod('createVirtualAccount', {
        'userId': userId,
        'amount': amount,
        'cardType': cardType,
        'cardNumber': _maskCardNumber(cardNumber),
        'expireMinutes': 30, // 30분 후 만료
      });

      return VirtualAccount.fromMap(response);
    } catch (e) {
      throw BankTransferException('가상계좌 생성 실패: $e');
    }
  }

  /// 실시간 계좌이체 처리
  Future<TransferResult> processDirectTransfer({
    required String fromBank,
    required String fromAccount,
    required String accountHolder,
    required int amount,
    required String pin, // 계좌 비밀번호 또는 인증번호
    required String cardId,
  }) async {
    try {
      // 계좌 유효성 검증
      final isValid = await _validateAccount(
        bank: fromBank,
        account: fromAccount,
        holder: accountHolder,
      );
      
      if (!isValid) {
        throw BankTransferException('유효하지 않은 계좌 정보입니다');
      }

      // PIN 암호화
      final encryptedPin = _encryptPin(pin);

      // 이체 처리
      final response = await _platform.invokeMethod('processTransfer', {
        'fromBank': fromBank,
        'fromAccount': fromAccount,
        'accountHolder': accountHolder,
        'amount': amount,
        'pin': encryptedPin,
        'toAccount': 'FREERIDER_CHARGE', // FREERIDER 충전 계좌
        'description': '교통카드 충전',
        'cardId': cardId,
      });

      return TransferResult.fromMap(response);
    } on PlatformException catch (e) {
      if (e.code == 'INSUFFICIENT_BALANCE') {
        throw BankTransferException('잔액이 부족합니다');
      } else if (e.code == 'INVALID_PIN') {
        throw BankTransferException('비밀번호가 일치하지 않습니다');
      } else if (e.code == 'DAILY_LIMIT_EXCEEDED') {
        throw BankTransferException('일일 이체 한도를 초과했습니다');
      }
      throw BankTransferException('이체 실패: ${e.message}');
    }
  }

  /// 오픈뱅킹 API를 통한 계좌 조회
  Future<List<BankAccount>> getUserBankAccounts(String userId) async {
    try {
      final response = await _platform.invokeMethod('getUserAccounts', {
        'userId': userId,
      });

      return (response as List)
          .map((account) => BankAccount.fromMap(account))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 계좌 잔액 조회
  Future<int> getAccountBalance({
    required String bank,
    required String account,
    required String pin,
  }) async {
    try {
      final encryptedPin = _encryptPin(pin);
      
      final balance = await _platform.invokeMethod('getBalance', {
        'bank': bank,
        'account': account,
        'pin': encryptedPin,
      });

      return balance as int;
    } catch (e) {
      throw BankTransferException('잔액 조회 실패: $e');
    }
  }

  /// 이체 내역 조회
  Future<List<TransferHistory>> getTransferHistory(String userId) async {
    try {
      final response = await _platform.invokeMethod('getTransferHistory', {
        'userId': userId,
        'type': 'CARD_CHARGE',
        'limit': 20,
      });

      return (response as List)
          .map((history) => TransferHistory.fromMap(history))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 계좌 유효성 검증
  Future<bool> _validateAccount({
    required String bank,
    required String account,
    required String holder,
  }) async {
    try {
      final result = await _platform.invokeMethod('validateAccount', {
        'bank': bank,
        'account': account,
        'holder': holder,
      });
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  /// PIN 암호화
  String _encryptPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 카드번호 마스킹
  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length < 8) return cardNumber;
    final first4 = cardNumber.substring(0, 4);
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '$first4****$last4';
  }

  /// 간편 송금 서비스 연동 (토스, 카카오페이 등)
  Future<QuickTransferResult> processQuickTransfer({
    required QuickTransferType type,
    required int amount,
    required String cardId,
  }) async {
    try {
      switch (type) {
        case QuickTransferType.toss:
          return await _processTossTransfer(amount, cardId);
        case QuickTransferType.kakaoPay:
          return await _processKakaoPayTransfer(amount, cardId);
        case QuickTransferType.naverPay:
          return await _processNaverPayTransfer(amount, cardId);
        default:
          throw BankTransferException('지원하지 않는 송금 방식입니다');
      }
    } catch (e) {
      throw BankTransferException('간편 송금 실패: $e');
    }
  }

  Future<QuickTransferResult> _processTossTransfer(int amount, String cardId) async {
    final response = await _platform.invokeMethod('processTossTransfer', {
      'amount': amount,
      'cardId': cardId,
      'description': 'FREERIDER 교통카드 충전',
    });
    return QuickTransferResult.fromMap(response);
  }

  Future<QuickTransferResult> _processKakaoPayTransfer(int amount, String cardId) async {
    final response = await _platform.invokeMethod('processKakaoPayTransfer', {
      'amount': amount,
      'cardId': cardId,
      'description': 'FREERIDER 교통카드 충전',
    });
    return QuickTransferResult.fromMap(response);
  }

  Future<QuickTransferResult> _processNaverPayTransfer(int amount, String cardId) async {
    final response = await _platform.invokeMethod('processNaverPayTransfer', {
      'amount': amount,
      'cardId': cardId,
      'description': 'FREERIDER 교통카드 충전',
    });
    return QuickTransferResult.fromMap(response);
  }
}

/// 가상계좌 정보
class VirtualAccount {
  final String accountNumber;
  final String bankName;
  final String bankCode;
  final int amount;
  final DateTime expireAt;
  final String depositorName;

  VirtualAccount({
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
    required this.amount,
    required this.expireAt,
    required this.depositorName,
  });

  factory VirtualAccount.fromMap(Map<dynamic, dynamic> map) {
    return VirtualAccount(
      accountNumber: map['accountNumber'],
      bankName: map['bankName'],
      bankCode: map['bankCode'],
      amount: map['amount'],
      expireAt: DateTime.parse(map['expireAt']),
      depositorName: map['depositorName'],
    );
  }
}

/// 은행 계좌 정보
class BankAccount {
  final String bank;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final int? balance;
  final bool isDefault;

  BankAccount({
    required this.bank,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.balance,
    this.isDefault = false,
  });

  factory BankAccount.fromMap(Map<dynamic, dynamic> map) {
    return BankAccount(
      bank: map['bank'],
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      accountHolder: map['accountHolder'],
      balance: map['balance'],
      isDefault: map['isDefault'] ?? false,
    );
  }
}

/// 이체 결과
class TransferResult {
  final bool success;
  final String transactionId;
  final int amount;
  final DateTime completedAt;
  final String? errorMessage;
  final int? newBalance;

  TransferResult({
    required this.success,
    required this.transactionId,
    required this.amount,
    required this.completedAt,
    this.errorMessage,
    this.newBalance,
  });

  factory TransferResult.fromMap(Map<dynamic, dynamic> map) {
    return TransferResult(
      success: map['success'],
      transactionId: map['transactionId'],
      amount: map['amount'],
      completedAt: DateTime.parse(map['completedAt']),
      errorMessage: map['errorMessage'],
      newBalance: map['newBalance'],
    );
  }
}

/// 이체 내역
class TransferHistory {
  final String transactionId;
  final int amount;
  final String fromAccount;
  final String toAccount;
  final DateTime transferredAt;
  final String status;
  final String description;

  TransferHistory({
    required this.transactionId,
    required this.amount,
    required this.fromAccount,
    required this.toAccount,
    required this.transferredAt,
    required this.status,
    required this.description,
  });

  factory TransferHistory.fromMap(Map<dynamic, dynamic> map) {
    return TransferHistory(
      transactionId: map['transactionId'],
      amount: map['amount'],
      fromAccount: map['fromAccount'],
      toAccount: map['toAccount'],
      transferredAt: DateTime.parse(map['transferredAt']),
      status: map['status'],
      description: map['description'],
    );
  }
}

/// 간편 송금 결과
class QuickTransferResult {
  final bool success;
  final String transactionId;
  final int amount;
  final String? errorMessage;

  QuickTransferResult({
    required this.success,
    required this.transactionId,
    required this.amount,
    this.errorMessage,
  });

  factory QuickTransferResult.fromMap(Map<dynamic, dynamic> map) {
    return QuickTransferResult(
      success: map['success'],
      transactionId: map['transactionId'],
      amount: map['amount'],
      errorMessage: map['errorMessage'],
    );
  }
}

/// 간편 송금 타입
enum QuickTransferType {
  toss,
  kakaoPay,
  naverPay,
}

/// 계좌이체 예외
class BankTransferException implements Exception {
  final String message;
  BankTransferException(this.message);
  
  @override
  String toString() => 'BankTransferException: $message';
}