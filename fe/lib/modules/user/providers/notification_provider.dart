// lib/modules/user/providers/notification_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  String _selectedFilter = 'all';

  List<NotificationModel> get notifications => _filteredNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  String get selectedFilter => _selectedFilter;

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'all') {
      return _notifications;
    }

    NotificationType? filterType;
    switch (_selectedFilter) {
      case 'order':
        filterType = NotificationType.order;
        break;
      case 'promotion':
        filterType = NotificationType.promotion;
        break;
      case 'product':
        filterType = NotificationType.product;
        break;
      case 'system':
        filterType = NotificationType.system;
        break;
    }

    return _notifications.where((n) => n.type == filterType).toList();
  }

  int getCountByType(String type) {
    if (type == 'all') return _notifications.length;
    
    NotificationType? filterType;
    switch (type) {
      case 'order':
        filterType = NotificationType.order;
        break;
      case 'promotion':
        filterType = NotificationType.promotion;
        break;
      case 'product':
        filterType = NotificationType.product;
        break;
      case 'system':
        filterType = NotificationType.system;
        break;
    }

    return _notifications.where((n) => n.type == filterType).length;
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Fetch notifications
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.NOTIFICATIONS);

      if (response.statusCode == 200) {
        final data = response.data;
        _notifications = (data['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _unreadCount = data['unreadCount'] ?? 0;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.notificationRead(notificationId),
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.put(
        ApiConfig.NOTIFICATIONS_READ_ALL,
      );

      if (response.statusCode == 200) {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('Mark all as read error: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete(
        ApiConfig.deleteNotification(notificationId),
      );

      if (response.statusCode == 200) {
        final notification = _notifications.firstWhere((n) => n.id == notificationId);
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
      }
    } catch (e) {
      print('Delete notification error: $e');
    }
  }

  // Get unread count (for badge)
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.NOTIFICATIONS_UNREAD_COUNT,
      );

      if (response.statusCode == 200) {
        _unreadCount = response.data['count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      print('Fetch unread count error: $e');
    }
  }

  Future<void> refresh() async {
    await fetchNotifications();
  }
}