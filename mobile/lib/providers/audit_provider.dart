import 'package:flutter_riverpod/legacy.dart';
import '../models/audit_log.dart';
import '../services/api_service.dart';

class AuditState {
  final List<AuditLog> logs;
  final bool isLoading;
  final String? error;

  AuditState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  AuditState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return AuditState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuditNotifier extends StateNotifier<AuditState> {
  final ApiService _apiService;

  AuditNotifier(this._apiService) : super(AuditState());

  Future<void> fetchAuditLogs({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true);
    try {
      final logs = await _apiService.getAuditLogs(limit: limit, offset: offset);
      state = state.copyWith(
        logs: logs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

final auditProvider = StateNotifierProvider<AuditNotifier, AuditState>((ref) {
  return AuditNotifier(ref.watch(apiServiceProvider));
});
