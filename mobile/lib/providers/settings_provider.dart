import 'package:flutter_riverpod/legacy.dart';
import '../models/system_settings.dart';
import '../services/settings_api_service.dart';

class SettingsState {
  final SystemSettings? settings;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  SettingsState({this.settings, this.isLoading = false, this.error, this.isSaving = false});

  SettingsState copyWith({
    SystemSettings? settings,
    bool? isLoading,
    String? error,
    bool? isSaving,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsApiService _api;

  SettingsNotifier(this._api) : super(SettingsState());

  Future<void> fetchSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = await _api.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        settings: state.settings ?? SystemSettings.defaults(),
      );
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true);
    try {
      final updated = await _api.updateSettings(data);
      state = state.copyWith(settings: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String current, String newPwd) async {
    state = state.copyWith(isSaving: true);
    try {
      await _api.changePassword(current, newPwd);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(settingsApiProvider));
});
