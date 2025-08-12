import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../models/activity_model.dart';

// Activity State Provider
final activityStateProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier();
});

// Step Count Stream Provider
final stepCountStreamProvider = StreamProvider<StepCount>((ref) async* {
  final permission = await Permission.activityRecognition.request();
  if (!permission.isGranted) {
    throw Exception('Activity recognition permission not granted');
  }
  
  await for (final step in Pedometer.stepCountStream) {
    yield step;
  }
});

// Location Stream Provider for transit detection
final locationStreamProvider = StreamProvider<Position>((ref) async* {
  final permission = await Permission.location.request();
  if (!permission.isGranted) {
    throw Exception('Location permission not granted');
  }
  
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100, // Update every 100 meters
  );
  
  await for (final position in Geolocator.getPositionStream(locationSettings: locationSettings)) {
    yield position;
  }
});

class ActivityState {
  final int todaySteps;
  final int todayFloors;
  final int cyclingMinutes;
  final int transitCount;
  final int totalPoints;
  final bool isTracking;
  final DateTime lastUpdated;
  final List<DailyActivity> activities;
  final TransitStatus? currentTransit;

  ActivityState({
    this.todaySteps = 0,
    this.todayFloors = 0,
    this.cyclingMinutes = 0,
    this.transitCount = 0,
    this.totalPoints = 0,
    this.isTracking = false,
    DateTime? lastUpdated,
    List<DailyActivity>? activities,
    this.currentTransit,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       activities = activities ?? [];

  ActivityState copyWith({
    int? todaySteps,
    int? todayFloors,
    int? cyclingMinutes,
    int? transitCount,
    int? totalPoints,
    bool? isTracking,
    DateTime? lastUpdated,
    List<DailyActivity>? activities,
    TransitStatus? currentTransit,
  }) {
    return ActivityState(
      todaySteps: todaySteps ?? this.todaySteps,
      todayFloors: todayFloors ?? this.todayFloors,
      cyclingMinutes: cyclingMinutes ?? this.cyclingMinutes,
      transitCount: transitCount ?? this.transitCount,
      totalPoints: totalPoints ?? this.totalPoints,
      isTracking: isTracking ?? this.isTracking,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      activities: activities ?? this.activities,
      currentTransit: currentTransit ?? this.currentTransit,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  ActivityNotifier() : super(ActivityState());

  void startTracking() {
    state = state.copyWith(isTracking: true);
  }

  void stopTracking() {
    state = state.copyWith(isTracking: false);
  }

  void updateSteps(int steps) {
    final previousSteps = state.todaySteps;
    final stepDifference = steps - previousSteps;
    
    if (stepDifference > 0) {
      // Calculate points for new steps
      final newPoints = (stepDifference / AppConstants.stepsPerPoint).floor();
      final totalStepPoints = state.totalPoints + newPoints;
      
      // Check daily limit
      final cappedPoints = totalStepPoints > AppConstants.walkingMaxPoints 
          ? AppConstants.walkingMaxPoints 
          : totalStepPoints;
      
      // Add activity record
      final activity = DailyActivity(
        type: ActivityType.walking,
        value: stepDifference,
        points: newPoints,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        todaySteps: steps,
        totalPoints: cappedPoints,
        lastUpdated: DateTime.now(),
        activities: [...state.activities, activity],
      );
    }
  }

  void updateFloors(int floors) {
    final newFloorPoints = floors * AppConstants.pointsPerFloor;
    final cappedPoints = newFloorPoints > AppConstants.stairsMaxPoints
        ? AppConstants.stairsMaxPoints
        : newFloorPoints;
    
    state = state.copyWith(
      todayFloors: floors,
      totalPoints: state.totalPoints + cappedPoints,
      lastUpdated: DateTime.now(),
    );
  }

  void detectTransitUse(Position position, {required double speed}) {
    // Simple transit detection based on speed
    // Walking: < 5 km/h
    // Cycling: 5-25 km/h  
    // Transit: > 25 km/h
    
    if (speed > 25 && state.currentTransit == null) {
      // Started using transit
      state = state.copyWith(
        currentTransit: TransitStatus(
          startTime: DateTime.now(),
          startPosition: position,
        ),
      );
    } else if (speed < 5 && state.currentTransit != null) {
      // Stopped using transit
      final duration = DateTime.now().difference(state.currentTransit!.startTime);
      if (duration.inMinutes > 5) {
        // Valid transit use (more than 5 minutes)
        _recordTransitUse();
      }
      state = state.copyWith(currentTransit: null);
    }
  }

  void _recordTransitUse() {
    if (state.transitCount >= 4) return; // Daily limit reached
    
    final newTransitCount = state.transitCount + 1;
    final points = AppConstants.pointsPerTransitUse;
    
    final activity = DailyActivity(
      type: ActivityType.transit,
      value: 1,
      points: points,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      transitCount: newTransitCount,
      totalPoints: state.totalPoints + points,
      activities: [...state.activities, activity],
      lastUpdated: DateTime.now(),
    );
  }

  void resetDaily() {
    state = ActivityState();
  }
}