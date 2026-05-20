class SystemSettings {
  final int id;
  final String appName;
  final String defaultCurrency;
  final bool useLiveRates;
  final Map<String, dynamic>? manualRates;
  final int sessionTimeoutMinutes;
  final Map<String, dynamic>? notificationDefaults;
  final int version;
  final String? updatedAt;
  final int? updatedBy;

  const SystemSettings({
    required this.id,
    required this.appName,
    required this.defaultCurrency,
    required this.useLiveRates,
    this.manualRates,
    required this.sessionTimeoutMinutes,
    this.notificationDefaults,
    required this.version,
    this.updatedAt,
    this.updatedBy,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      id: json['id'] ?? 1,
      appName: json['app_name'] ?? 'Expense Tracker',
      defaultCurrency: json['default_currency'] ?? 'USD',
      useLiveRates: json['use_live_rates'] ?? true,
      manualRates: json['manual_rates'] as Map<String, dynamic>?,
      sessionTimeoutMinutes: json['session_timeout_minutes'] ?? 1440,
      notificationDefaults: json['notification_defaults'] as Map<String, dynamic>?,
      version: json['version'] ?? 1,
      updatedAt: json['updated_at'],
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toUpdateJson(int currentVersion) {
    return {
      'app_name': appName,
      'default_currency': defaultCurrency,
      'use_live_rates': useLiveRates,
      'manual_rates': manualRates,
      'session_timeout_minutes': sessionTimeoutMinutes,
      'notification_defaults': notificationDefaults,
      'version': currentVersion,
    };
  }

  static SystemSettings defaults() {
    return const SystemSettings(
      id: 1,
      appName: 'Expense Tracker',
      defaultCurrency: 'USD',
      useLiveRates: true,
      manualRates: {'USD_TZS': 2500.0, 'USD_KES': 130.0},
      sessionTimeoutMinutes: 1440,
      notificationDefaults: {'type': 'info', 'priority': 'normal'},
      version: 1,
    );
  }
}
