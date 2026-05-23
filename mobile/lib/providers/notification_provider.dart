import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadMoreLoading;
  final bool hasReachedMax;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadMoreLoading = false,
    this.hasReachedMax = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadMoreLoading,
    bool? hasReachedMax,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadMoreLoading: isLoadMoreLoading ?? this.isLoadMoreLoading,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _apiService;
  final NotificationService _notificationService;
  StreamSubscription? _notifSubscription;

  NotificationNotifier(this._apiService, this._notificationService) : super(NotificationState()) {
    _notifSubscription = _notificationService.newNotificationStream.listen((notif) {
      _onNewNotificationReceived(notif);
    });
  }

  void _onNewNotificationReceived(AppNotification notif) {
    final exists = state.notifications.any((e) => e.id == notif.id);
    if (!exists) {
      state = state.copyWith(
        notifications: [notif, ...state.notifications],
      );
    }
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (state.isLoading || state.isLoadMoreLoading) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        hasReachedMax: false,
        notifications: [],
      );
    } else {
      if (state.hasReachedMax) return;
      state = state.copyWith(isLoadMoreLoading: true);
    }

    try {
      final offset = refresh ? 0 : state.notifications.length;
      final newNotifications = await _apiService.getNotifications(
        limit: 20,
        offset: offset,
      );

      state = state.copyWith(
        notifications: refresh 
            ? newNotifications 
            : [...state.notifications, ...newNotifications],
        isLoading: false,
        isLoadMoreLoading: false,
        hasReachedMax: newNotifications.length < 20,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isLoadMoreLoading: false,
      );
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _apiService.markAsRead(notificationId: notificationId);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.notificationId == notificationId) {
            return AppNotification(
              id: n.id,
              notificationId: n.notificationId,
              title: n.title,
              message: n.message,
              type: n.type,
              priority: n.priority,
              isBroadcast: n.isBroadcast,
              createdAt: n.createdAt,
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return n;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAsRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          return AppNotification(
            id: n.id,
            notificationId: n.notificationId,
            title: n.title,
            message: n.message,
            type: n.type,
            priority: n.priority,
            isBroadcast: n.isBroadcast,
            createdAt: n.createdAt,
            isRead: true,
            readAt: DateTime.now(),
          );
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  // Let's get the standard ApiService
  final apiService = ApiService(); // or ref.watch(apiServiceProvider) if it exists, wait, apiServiceProvider is defined in api_service.dart
  final service = NotificationService(apiService);
  ref.onDispose(() => service.dispose());
  return service;
});

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiService = ApiService();
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(apiService, service);
});
