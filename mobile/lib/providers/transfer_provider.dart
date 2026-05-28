import 'package:flutter_riverpod/legacy.dart';
import '../models/transfer.dart';
import '../services/api_service.dart';

class TransferState {
  final List<Transfer> transfers;
  final bool isLoading;
  final String? error;

  TransferState({
    this.transfers = const [],
    this.isLoading = false,
    this.error,
  });

  TransferState copyWith({
    List<Transfer>? transfers,
    bool? isLoading,
    String? error,
  }) {
    return TransferState(
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TransferNotifier extends StateNotifier<TransferState> {
  final ApiService _apiService;

  TransferNotifier(this._apiService) : super(TransferState());

  Future<void> fetchTransfers({
    String? startDate,
    String? endDate,
    int? userId,
    List<String>? projects,
    int? projectId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final transfers = await _apiService.getTransfers(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        projects: projects,
        projectId: projectId,
      );
      state = state.copyWith(transfers: transfers, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addTransfer(Transfer transfer) async {
    state = state.copyWith(isLoading: true);
    try {
      final newTransfer = await _apiService.createTransfer(transfer);
      state = state.copyWith(
        transfers: [newTransfer, ...state.transfers],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateTransfer(int id, Transfer transfer) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedTransfer = await _apiService.updateTransfer(id, transfer);
      state = state.copyWith(
        transfers: state.transfers.map((e) => e.id == id ? updatedTransfer : e).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteTransfer(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteTransfer(id);
      state = state.copyWith(
        transfers: state.transfers.where((e) => e.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  return TransferNotifier(ref.watch(apiServiceProvider));
});
