class TransitCard {
  final String id;
  final String type; // T-money, Cashbee, etc.
  final String cardNumber;
  final String maskedNumber;
  final int balance;
  final bool isDefault;
  final DateTime registeredAt;
  final DateTime? lastChargedAt;
  final int totalCharged;

  TransitCard({
    required this.id,
    required this.type,
    required this.cardNumber,
    required this.maskedNumber,
    required this.balance,
    this.isDefault = false,
    required this.registeredAt,
    this.lastChargedAt,
    this.totalCharged = 0,
  });

  TransitCard copyWith({
    String? id,
    String? type,
    String? cardNumber,
    String? maskedNumber,
    int? balance,
    bool? isDefault,
    DateTime? registeredAt,
    DateTime? lastChargedAt,
    int? totalCharged,
  }) {
    return TransitCard(
      id: id ?? this.id,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      balance: balance ?? this.balance,
      isDefault: isDefault ?? this.isDefault,
      registeredAt: registeredAt ?? this.registeredAt,
      lastChargedAt: lastChargedAt ?? this.lastChargedAt,
      totalCharged: totalCharged ?? this.totalCharged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'cardNumber': cardNumber,
      'maskedNumber': maskedNumber,
      'balance': balance,
      'isDefault': isDefault,
      'registeredAt': registeredAt.toIso8601String(),
      'lastChargedAt': lastChargedAt?.toIso8601String(),
      'totalCharged': totalCharged,
    };
  }

  factory TransitCard.fromJson(Map<String, dynamic> json) {
    return TransitCard(
      id: json['id'],
      type: json['type'],
      cardNumber: json['cardNumber'],
      maskedNumber: json['maskedNumber'],
      balance: json['balance'],
      isDefault: json['isDefault'] ?? false,
      registeredAt: DateTime.parse(json['registeredAt']),
      lastChargedAt: json['lastChargedAt'] != null
          ? DateTime.parse(json['lastChargedAt'])
          : null,
      totalCharged: json['totalCharged'] ?? 0,
    );
  }
}

class ChargeHistory {
  final String id;
  final String cardId;
  final int amount;
  final int pointsUsed;
  final DateTime chargedAt;
  final String status; // pending, completed, failed

  ChargeHistory({
    required this.id,
    required this.cardId,
    required this.amount,
    required this.pointsUsed,
    required this.chargedAt,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'amount': amount,
      'pointsUsed': pointsUsed,
      'chargedAt': chargedAt.toIso8601String(),
      'status': status,
    };
  }

  factory ChargeHistory.fromJson(Map<String, dynamic> json) {
    return ChargeHistory(
      id: json['id'],
      cardId: json['cardId'],
      amount: json['amount'],
      pointsUsed: json['pointsUsed'],
      chargedAt: DateTime.parse(json['chargedAt']),
      status: json['status'],
    );
  }
}