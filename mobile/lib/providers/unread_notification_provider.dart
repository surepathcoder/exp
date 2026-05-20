import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class UnreadNotificationNotifier extends StateNotifier<int> {
  final NotificationService _notificationService;
  StreamSubscription? _subscription;

  UnreadNotificationNotifier(this._notificationService) : super(0) {
    _subscription = _notificationService.unreadCountStream.listen((count) {
      state = count;
    });
    // Start polling automatically
    _notificationService.startPolling();
  }

  Future<void> refreshCount() async {
    try {
      final apiService = ApiService();
      final count = await apiService.getUnreadCount();
      state = count;
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationService.stopPolling();
    super.dispose();
  }
}

final unreadNotificationProvider = StateNotifierProvider<UnreadNotificationNotifier, int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return UnreadNotificationNotifier(service);
});
