import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reports_api_service.dart';
import '../utils/downloader.dart';

class ReportsState {
  final bool isLoading;
  final bool isExporting;
  final String? error;
  final String reportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> selectedCategories;
  final List<String> selectedProjects;
  final int? selectedUserId;
  final String search;
  final Map<String, dynamic>? previewData;

  ReportsState({
    required this.isLoading,
    required this.isExporting,
    this.error,
    required this.reportType,
    this.startDate,
    this.endDate,
    required this.selectedCategories,
    required this.selectedProjects,
    this.selectedUserId,
    required this.search,
    this.previewData,
  });

  factory ReportsState.initial() {
    final now = DateTime.now();
    return ReportsState(
      isLoading: false,
      isExporting: false,
      reportType: 'combined',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      selectedCategories: [],
      selectedProjects: [],
      search: '',
    );
  }

  ReportsState copyWith({
    bool? isLoading,
    bool? isExporting,
    String? error,
    String? reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedCategories,
    List<String>? selectedProjects,
    int? selectedUserId,
    String? search,
    Map<String, dynamic>? previewData,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: error,
      reportType: reportType ?? this.reportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedProjects: selectedProjects ?? this.selectedProjects,
      selectedUserId: selectedUserId, // Allows setting to null explicitly
      search: search ?? this.search,
      previewData: previewData ?? this.previewData,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsApiService _apiService;

  ReportsNotifier(this._apiService) : super(ReportsState.initial()) {
    fetchPreview();
  }

  Future<void> fetchPreview() async {
    state = state.copyWith(isLoading: true);
    try {
      final preview = await _apiService.getReportsPreview(
        reportType: state.reportType,
        startDate: state.startDate?.toIso8601String(),
        endDate: state.endDate?.toIso8601String(),
        categories: state.selectedCategories,
        userId: state.selectedUserId,
        projects: state.selectedProjects,
        search: state.search,
      );
      state = state.copyWith(isLoading: false, previewData: preview);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateFilters({
    String? reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    List<String>? projects,
    int? userId,
    String? search,
    bool clearUser = false,
    bool clearDates = false,
  }) {
    state = state.copyWith(
      reportType: reportType,
      startDate: clearDates ? null : (startDate ?? state.startDate),
      endDate: clearDates ? null : (endDate ?? state.endDate),
      selectedCategories: categories,
      selectedProjects: projects,
      selectedUserId: clearUser ? null : (userId ?? state.selectedUserId),
      search: search,
    );
    fetchPreview();
  }

  Future<bool> exportReport(String format) async {
    state = state.copyWith(isExporting: true);
    try {
      List<int> bytes;
      final filename = 'financial_report_${state.reportType}_${DateTime.now().millisecondsSinceEpoch}.$format';
      
      if (format == 'csv') {
        bytes = await _apiService.downloadReportsCsv(
          reportType: state.reportType,
          startDate: state.startDate?.toIso8601String(),
          endDate: state.endDate?.toIso8601String(),
          categories: state.selectedCategories,
          userId: state.selectedUserId,
          projects: state.selectedProjects,
          search: state.search,
        );
      } else {
        bytes = await _apiService.downloadReportsPdf(
          reportType: state.reportType,
          startDate: state.startDate?.toIso8601String(),
          endDate: state.endDate?.toIso8601String(),
          categories: state.selectedCategories,
          userId: state.selectedUserId,
          projects: state.selectedProjects,
          search: state.search,
        );
      }
      
      await downloadFile(bytes, filename);
      state = state.copyWith(isExporting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
      return false;
    }
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final apiService = ref.watch(reportsApiServiceProvider);
  return ReportsNotifier(apiService);
});
