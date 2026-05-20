import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiService _apiService;
  Timer? _pollingTimer;
  final _unreadController = StreamController<int>.broadcast();
  final _newNotificationController = StreamController<AppNotification>.broadcast();
  
  int _lastUnreadCount = 0;
  List<int> _seenIds = [];

  NotificationService(this._apiService);

  Stream<int> get unreadCountStream => _unreadController.stream;
  Stream<AppNotification> get newNotificationStream => _newNotificationController.stream;

  void startPolling() {
    _pollingTimer?.cancel();
    // Poll every 5 seconds for responsive real-time feel
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _poll(); // Run initial poll immediately
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _poll() async {
    try {
      final unreadCount = await _apiService.getUnreadCount();
      if (unreadCount != _lastUnreadCount) {
        _lastUnreadCount = unreadCount;
        _unreadController.add(unreadCount);
      }

      // Fetch the latest notifications to check for new alerts
      final latest = await _apiService.getNotifications(limit: 5);
      for (final notif in latest) {
        if (!notif.isRead && !_seenIds.contains(notif.id)) {
          _seenIds.add(notif.id);
          _newNotificationController.add(notif);
        }
      }
      
      // Keep seen array compact
      if (_seenIds.length > 50) {
        _seenIds = _seenIds.sublist(_seenIds.length - 20);
      }
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    }
  }

  void dispose() {
    stopPolling();
    _unreadController.close();
    _newNotificationController.close();
  }
}
