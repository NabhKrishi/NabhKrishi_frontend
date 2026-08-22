import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../data/repositories/irrigation_repository.dart';
import '../models/irrigation_models.dart';

class IrrigationState {
  final bool isLoading;
  final String loadingStage; // key for localization e.g. 'loading_weather'
  final LocationPredictionResponse? data;
  final String? errorMessage;
  final bool isColdStart;

  IrrigationState({
    this.isLoading = false,
    this.loadingStage = '',
    this.data,
    this.errorMessage,
    this.isColdStart = false,
  });

  IrrigationState copyWith({
    bool? isLoading,
    String? loadingStage,
    LocationPredictionResponse? data,
    String? errorMessage,
    bool? isColdStart,
  }) {
    return IrrigationState(
      isLoading: isLoading ?? this.isLoading,
      loadingStage: loadingStage ?? this.loadingStage,
      data: data ?? this.data,
      errorMessage: errorMessage, // We clear error message if not explicitly passed
      isColdStart: isColdStart ?? this.isColdStart,
    );
  }
}

class IrrigationNotifier extends FamilyNotifier<IrrigationState, String> {
  late final IrrigationRepository _repository;
  bool _isFetching = false;

  @override
  IrrigationState build(String arg) {
    _repository = IrrigationRepository();
    
    // Parse the coordinate key 'latitude,longitude'
    final parts = arg.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        // Trigger fetch asynchronously to avoid modifying state during the build phase
        Future.microtask(() => fetchRecommendation(lat, lng));
        return IrrigationState(
          isLoading: true,
          loadingStage: 'loading_weather',
        );
      }
    }
    
    return IrrigationState();
  }

  Future<void> fetchRecommendation(double latitude, double longitude) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!state.isLoading) {
      state = IrrigationState(
        isLoading: true,
        loadingStage: 'loading_weather',
      );
    }

    // Setup a timer to simulate loading stages to the farmer,
    // since the backend /predict-location endpoint aggregates all data in a single call.
    int stage = 0;
    final List<String> stages = [
      'loading_weather',
      'loading_satellite',
      'loading_analysis',
      'loading_recommendation'
    ];

    Timer? stageTimer;
    stageTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (stage < stages.length - 1) {
        stage++;
        if (state.isLoading) {
          state = state.copyWith(loadingStage: stages[stage]);
        }
      } else {
        timer.cancel();
      }
    });

    // Also handle Render cold starts. If the API takes more than 5 seconds,
    // show "Starting NabhKrishi services..." instead of immediately failing or showing a generic loading message.
    final coldStartTimer = Timer(const Duration(seconds: 5), () {
      if (state.isLoading) {
        state = state.copyWith(loadingStage: 'loading_cold_start', isColdStart: true);
      }
    });

    try {
      final response = await _repository.predictLocation(latitude, longitude);
      
      stageTimer.cancel();
      coldStartTimer.cancel();
      _isFetching = false;
      
      state = IrrigationState(
        isLoading: false,
        data: response,
      );
    } catch (e) {
      stageTimer.cancel();
      coldStartTimer.cancel();
      _isFetching = false;
      
      String userError = 'error_generic';
      if (e is NetworkException && e.statusCode == 502) {
        userError = 'error_502';
      } else if (e.toString().contains('timeout') || e.toString().contains('warming up')) {
        userError = 'loading_cold_start';
      }
      
      state = IrrigationState(
        isLoading: false,
        errorMessage: userError,
      );
    }
  }
}

final irrigationProvider = NotifierProviderFamily<IrrigationNotifier, IrrigationState, String>(() {
  return IrrigationNotifier();
});
