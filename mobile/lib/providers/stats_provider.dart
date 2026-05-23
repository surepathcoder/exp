import 'package:flutter_riverpod/legacy.dart';
import '../models/system_stats.dart';
import '../models/audit_log.dart';
import '../services/settings_api_service.dart';

class StatsState {
  final SystemStats stats;
  final List<AuditLog> auditLogs;
  final bool isLoading;
  final String? error;

  StatsState({
    SystemStats? stats,
    this.auditLogs = const [],
    this.isLoading = false,
    this.error,
  }) : stats = stats ?? SystemStats.empty();

  StatsState copyWith({
    SystemStats? stats,
    List<AuditLog>? auditLogs,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      stats: stats ?? this.stats,
      auditLogs: auditLogs ?? this.auditLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final SettingsApiService _api;

  StatsNotifier(this._api) : super(StatsState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getAuditLogs(limit: 20),
      ]);
      state = state.copyWith(
        stats: results[0] as SystemStats,
        auditLogs: results[1] as List<AuditLog>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref.watch(settingsApiProvider));
});
