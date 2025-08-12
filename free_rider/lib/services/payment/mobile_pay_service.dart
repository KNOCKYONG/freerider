import 'dart:io';
import 'package:flutter/services.dart';

/// 모바일 페이 연동 서비스
/// Samsung Pay, Apple Pay API 통합
class MobilePayService {
  static const _platform = MethodChannel('com.freerider.payment/mobile_pay');
  
  // 싱글톤 인스턴스
  static final MobilePayService _instance = MobilePayService._internal();
  factory MobilePayService() => _instance;
  MobilePayService._internal();

  /// 모바일 페이 사용 가능 여부 확인
  Future<bool> isAvailable() async {
    try {
      if (Platform.isAndroid) {
        return await _checkSamsungPayAvailability();
      } else if (Platform.isIOS) {
        return await _checkApplePayAvailability();
      }
      return false;
    } catch (e) {
      print('Error checking mobile pay availability: $e');
      return false;
    }
  }

  /// Samsung Pay 사용 가능 여부 확인
  Future<bool> _checkSamsungPayAvailability() async {
    try {
      final bool isAvailable = await _platform.invokeMethod('isSamsungPayAvailable');
      return isAvailable;
    } on PlatformException catch (e) {
      print('Samsung Pay availability check failed: $e');
      return false;
    }
  }

  /// Apple Pay 사용 가능 여부 확인
  Future<bool> _checkApplePayAvailability() async {
    try {
      final bool canMakePayments = await _platform.invokeMethod('canMakePayments');
      if (!canMakePayments) return false;
      
      // 등록된 카드 확인
      final bool hasCards = await _platform.invokeMethod('hasRegisteredCards', {
        'networks': ['visa', 'masterCard', 'amex'],
      });
      return hasCards;
    } on PlatformException catch (e) {
      print('Apple Pay availability check failed: $e');
      return false;
    }
  }

  /// 교통카드 충전 요청
  Future<PaymentResult> chargeTransitCard({
    required String cardId,
    required int amount,
    required String cardType, // T-money, Cashbee, etc.
  }) async {
    try {
      if (Platform.isAndroid) {
        return await _chargeSamsungPay(cardId, amount, cardType);
      } else if (Platform.isIOS) {
        return await _chargeApplePay(cardId, amount, cardType);
      }
      throw UnsupportedError('Platform not supported');
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Samsung Pay로 충전
  Future<PaymentResult> _chargeSamsungPay(
    String cardId,
    int amount,
    String cardType,
  ) async {
    try {
      final Map<String, dynamic> result = await _platform.invokeMethod(
        'processSamsungPayment',
        {
          'merchantName': 'FREERIDER',
          'merchantId': 'freerider_transit',
          'orderNumber': 'TRN${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount.toString(),
          'currency': 'KRW',
          'cardType': cardType,
          'cardId': cardId,
          'itemName': '$cardType 충전',
          'serviceId': 'TRANSIT_CHARGE',
        },
      );
      
      return PaymentResult(
        success: result['success'] ?? false,
        transactionId: result['transactionId'],
        errorMessage: result['error'],
      );
    } on PlatformException catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Samsung Pay 결제 실패: ${e.message}',
      );
    }
  }

  /// Apple Pay로 충전
  Future<PaymentResult> _chargeApplePay(
    String cardId,
    int amount,
    String cardType,
  ) async {
    try {
      // Apple Pay 결제 요청 구성
      final paymentRequest = {
        'merchantIdentifier': 'merchant.com.freerider.transit',
        'merchantName': 'FREERIDER',
        'countryCode': 'KR',
        'currencyCode': 'KRW',
        'supportedNetworks': ['visa', 'masterCard', 'amex'],
        'merchantCapabilities': ['3DS', 'EMV'],
        'paymentSummaryItems': [
          {
            'label': '$cardType 충전',
            'amount': amount.toString(),
            'type': 'final',
          },
        ],
        'metadata': {
          'cardId': cardId,
          'cardType': cardType,
          'service': 'transit_charge',
        },
      };
      
      final Map<String, dynamic> result = await _platform.invokeMethod(
        'processApplePayment',
        paymentRequest,
      );
      
      if (result['success'] == true) {
        // 토큰을 서버로 전송하여 실제 결제 처리
        return await _processApplePayToken(
          result['paymentToken'],
          cardId,
          amount,
        );
      }
      
      return PaymentResult(
        success: false,
        errorMessage: result['error'] ?? 'Apple Pay 결제 실패',
      );
    } on PlatformException catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Apple Pay 결제 실패: ${e.message}',
      );
    }
  }

  /// Apple Pay 토큰 처리
  Future<PaymentResult> _processApplePayToken(
    String token,
    String cardId,
    int amount,
  ) async {
    // 실제 환경에서는 서버로 토큰을 전송하여 처리
    // 여기서는 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));
    
    return PaymentResult(
      success: true,
      transactionId: 'APL${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// NFC 교통카드 직접 충전 (Android Only)
  Future<PaymentResult> chargeNFCCard({
    required String cardNumber,
    required int amount,
  }) async {
    if (!Platform.isAndroid) {
      return PaymentResult(
        success: false,
        errorMessage: 'NFC 충전은 Android에서만 가능합니다',
      );
    }
    
    try {
      final Map<String, dynamic> result = await _platform.invokeMethod(
        'chargeNFCCard',
        {
          'cardNumber': cardNumber,
          'amount': amount,
        },
      );
      
      return PaymentResult(
        success: result['success'] ?? false,
        transactionId: result['transactionId'],
        balance: result['newBalance'],
        errorMessage: result['error'],
      );
    } on PlatformException catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'NFC 충전 실패: ${e.message}',
      );
    }
  }

  /// 등록된 교통카드 목록 가져오기
  Future<List<TransitCardInfo>> getRegisteredCards() async {
    try {
      if (Platform.isAndroid) {
        return await _getSamsungPayCards();
      } else if (Platform.isIOS) {
        return await _getApplePayCards();
      }
      return [];
    } catch (e) {
      print('Error getting registered cards: $e');
      return [];
    }
  }

  /// Samsung Pay 등록 카드 목록
  Future<List<TransitCardInfo>> _getSamsungPayCards() async {
    try {
      final List<dynamic> cards = await _platform.invokeMethod('getSamsungPayCards');
      return cards.map((card) => TransitCardInfo.fromMap(card)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Apple Pay 등록 카드 목록
  Future<List<TransitCardInfo>> _getApplePayCards() async {
    try {
      final List<dynamic> cards = await _platform.invokeMethod('getApplePayCards');
      return cards.map((card) => TransitCardInfo.fromMap(card)).toList();
    } catch (e) {
      return [];
    }
  }
}

/// 결제 결과 모델
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final int? balance;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.balance,
  });
}

/// 교통카드 정보 모델
class TransitCardInfo {
  final String id;
  final String type; // T-money, Cashbee, etc.
  final String lastFourDigits;
  final int balance;
  final bool isDefault;

  TransitCardInfo({
    required this.id,
    required this.type,
    required this.lastFourDigits,
    required this.balance,
    this.isDefault = false,
  });

  factory TransitCardInfo.fromMap(Map<dynamic, dynamic> map) {
    return TransitCardInfo(
      id: map['id'] ?? '',
      type: map['type'] ?? 'Unknown',
      lastFourDigits: map['lastFourDigits'] ?? '****',
      balance: map['balance'] ?? 0,
      isDefault: map['isDefault'] ?? false,
    );
  }
}