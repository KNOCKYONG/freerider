import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../models/card_model.dart';

// Card State Provider
final cardStateProvider = StateNotifierProvider<CardNotifier, CardState>((ref) {
  return CardNotifier();
});

// Selected Card Provider
final selectedCardProvider = Provider<TransitCard?>((ref) {
  final state = ref.watch(cardStateProvider);
  return state.selectedCard;
});

class CardState {
  final List<TransitCard> cards;
  final TransitCard? selectedCard;
  final List<ChargeHistory> chargeHistory;
  final int currentPoints;
  final bool isAutoChargeEnabled;
  final DateTime? lastChargedAt;
  final int todayChargedAmount;

  CardState({
    this.cards = const [],
    this.selectedCard,
    this.chargeHistory = const [],
    this.currentPoints = 0,
    this.isAutoChargeEnabled = true,
    this.lastChargedAt,
    this.todayChargedAmount = 0,
  });

  CardState copyWith({
    List<TransitCard>? cards,
    TransitCard? selectedCard,
    List<ChargeHistory>? chargeHistory,
    int? currentPoints,
    bool? isAutoChargeEnabled,
    DateTime? lastChargedAt,
    int? todayChargedAmount,
  }) {
    return CardState(
      cards: cards ?? this.cards,
      selectedCard: selectedCard ?? this.selectedCard,
      chargeHistory: chargeHistory ?? this.chargeHistory,
      currentPoints: currentPoints ?? this.currentPoints,
      isAutoChargeEnabled: isAutoChargeEnabled ?? this.isAutoChargeEnabled,
      lastChargedAt: lastChargedAt ?? this.lastChargedAt,
      todayChargedAmount: todayChargedAmount ?? this.todayChargedAmount,
    );
  }

  bool get canCharge => currentPoints >= AppConstants.dailyTargetPoints;
  bool get hasChargedToday {
    if (lastChargedAt == null) return false;
    final now = DateTime.now();
    return lastChargedAt!.year == now.year &&
           lastChargedAt!.month == now.month &&
           lastChargedAt!.day == now.day;
  }
}

class CardNotifier extends StateNotifier<CardState> {
  CardNotifier() : super(CardState()) {
    // Initialize with mock data
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock card for demo
    final mockCard = TransitCard(
      id: 'card_001',
      type: 'T-money',
      cardNumber: '1234567890123456',
      maskedNumber: '•••• •••• •••• 3456',
      balance: 5000,
      isDefault: true,
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    
    state = state.copyWith(
      cards: [mockCard],
      selectedCard: mockCard,
      currentPoints: 1550, // Start with enough points for demo
    );
  }

  void addCard(TransitCard card) {
    final updatedCards = [...state.cards, card];
    state = state.copyWith(
      cards: updatedCards,
      selectedCard: state.selectedCard ?? card,
    );
  }

  void selectCard(String cardId) {
    final card = state.cards.firstWhere((c) => c.id == cardId);
    state = state.copyWith(selectedCard: card);
  }

  void removeCard(String cardId) {
    final updatedCards = state.cards.where((c) => c.id != cardId).toList();
    final newSelectedCard = state.selectedCard?.id == cardId
        ? updatedCards.isNotEmpty ? updatedCards.first : null
        : state.selectedCard;
    
    state = state.copyWith(
      cards: updatedCards,
      selectedCard: newSelectedCard,
    );
  }

  void updatePoints(int points) {
    state = state.copyWith(currentPoints: points);
    
    // Auto charge if enabled and has enough points
    if (state.isAutoChargeEnabled && 
        state.canCharge && 
        !state.hasChargedToday &&
        state.selectedCard != null) {
      chargeCard(AppConstants.dailyTargetPoints);
    }
  }

  void chargeCard(int points) {
    if (!state.canCharge || state.selectedCard == null) return;
    
    // Update card balance
    final updatedCard = state.selectedCard!.copyWith(
      balance: state.selectedCard!.balance + points,
      lastChargedAt: DateTime.now(),
      totalCharged: state.selectedCard!.totalCharged + points,
    );
    
    // Update cards list
    final updatedCards = state.cards.map((card) {
      return card.id == updatedCard.id ? updatedCard : card;
    }).toList();
    
    // Create charge history record
    final chargeRecord = ChargeHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardId: updatedCard.id,
      amount: points,
      pointsUsed: points,
      chargedAt: DateTime.now(),
      status: 'completed',
    );
    
    state = state.copyWith(
      cards: updatedCards,
      selectedCard: updatedCard,
      currentPoints: state.currentPoints - points,
      chargeHistory: [...state.chargeHistory, chargeRecord],
      lastChargedAt: DateTime.now(),
      todayChargedAmount: state.todayChargedAmount + points,
    );
  }

  void toggleAutoCharge() {
    state = state.copyWith(
      isAutoChargeEnabled: !state.isAutoChargeEnabled,
    );
  }

  void resetDailyCharge() {
    state = state.copyWith(
      todayChargedAmount: 0,
    );
  }
}