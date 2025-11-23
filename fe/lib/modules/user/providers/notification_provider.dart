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
      case 'system':
        filterType = NotificationType.system;
        break;
    }

    return _notifications.where((n) => n.type == filterType).length;
  }

  bool hasUnreadByType(String type) {
    if (type == 'all') {
      return _notifications.any((n) => !n.isRead);
    }
    
    NotificationType? filterType;
    switch (type) {
      case 'order':
        filterType = NotificationType.order;
        break;
      case 'promotion':
        filterType = NotificationType.promotion;
        break;
      case 'system':
        filterType = NotificationType.system;
        break;
    }

    return _notifications.any((n) => n.type == filterType && !n.isRead);
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // ✅ ✅ ✅ FETCH NOTIFICATIONS VỚI DEBUG LOGS CHI TIẾT ✅ ✅ ✅
  Future<void> fetchNotifications() async {
    print('');
    print('🔄 ==================== FETCH NOTIFICATIONS START ====================');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 API URL: ${ApiConfig.NOTIFICATIONS}');
      final response = await _apiClient.get(ApiConfig.NOTIFICATIONS);

      print('✅ Response status: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');
      print('📦 Full response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // ✅ CHECK: Response structure
        print('');
        print('🔍 Keys in response: ${data.keys.toList()}');
        print('🔍 Has "notifications" key: ${data.containsKey('notifications')}');
        print('🔍 Has "unreadCount" key: ${data.containsKey('unreadCount')}');
        
        // Parse notifications
        if (data['notifications'] != null) {
          if (data['notifications'] is List) {
            final notificationsList = data['notifications'] as List;
            print('📊 Total notifications in response: ${notificationsList.length}');
            
            _notifications = notificationsList
                .map((json) => NotificationModel.fromJson(json))
                .toList();
            
            print('📊 Notifications successfully parsed: ${_notifications.length}');
            print('');
            
            // ✅ DEBUG: Print each notification's status
            for (var i = 0; i < _notifications.length; i++) {
              final n = _notifications[i];
              print('  [$i] Title: "${n.title}"');
              print('      Type: ${n.type}');
              print('      isRead: ${n.isRead}');
              print('      Created: ${n.timeAgo}');
            }
            
            // Count manually from list
            final manualUnreadCount = _notifications.where((n) => !n.isRead).length;
            print('');
            print('🔢 Manual unread count (from list): $manualUnreadCount');
            
          } else {
            print('❌ ERROR: "notifications" is not a List!');
            print('❌ Type: ${data['notifications'].runtimeType}');
          }
        } else {
          print('❌ ERROR: "notifications" is null!');
        }
        
        // Get unreadCount from response
if (data.containsKey('unreadCount')) {
  final apiUnreadCount = data['unreadCount'];
  print('✅ unreadCount from API: $apiUnreadCount (type: ${apiUnreadCount.runtimeType})');
  
  // ✅ FIX: So sánh với manual count
  final manualCount = _notifications.where((n) => !n.isRead).length;
  
  if (apiUnreadCount == 0 && manualCount > 0) {
    print('⚠️ WARNING: API returned 0 but list has $manualCount unread');
    print('🔄 Using manual count instead of API count');
    _unreadCount = manualCount; // ← Dùng manual count
  } else {
    _unreadCount = apiUnreadCount is int ? apiUnreadCount : (apiUnreadCount ?? 0);
  }
} else {
  print('⚠️ WARNING: No "unreadCount" in response');
  // Fallback: count from list
  _unreadCount = _notifications.where((n) => !n.isRead).length;
  print('🔄 Using fallback unreadCount: $_unreadCount');
}
        
        print('');
        print('🎯 FINAL unreadCount: $_unreadCount');
        print('🎯 FINAL notifications length: ${_notifications.length}');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      print('❌ ❌ ❌ ERROR OCCURRED ❌ ❌ ❌');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🔄 ==================== FETCH NOTIFICATIONS END ====================');
      print('');
    }
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      print('📝 Marking notification as read: $notificationId');
      final response = await _apiClient.put(
        ApiConfig.notificationRead(notificationId),
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          print('✅ Marked as read. New unreadCount: $_unreadCount');
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Mark as read error: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      print('📝 Marking all notifications as read...');
      final response = await _apiClient.put(
        ApiConfig.NOTIFICATIONS_READ_ALL,
      );

      if (response.statusCode == 200) {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _unreadCount = 0;
        print('✅ Marked all as read. unreadCount: 0');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Mark all as read error: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('🗑️ Deleting notification: $notificationId');
      final response = await _apiClient.delete(
        ApiConfig.deleteNotification(notificationId),
      );

      if (response.statusCode == 200) {
        final notification = _notifications.firstWhere((n) => n.id == notificationId);
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
        _notifications.removeWhere((n) => n.id == notificationId);
        print('✅ Deleted. New unreadCount: $_unreadCount');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Delete notification error: $e');
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
        print('✅ Fetched unreadCount: $_unreadCount');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Fetch unread count error: $e');
    }
  }

  Future<void> refresh() async {
    await fetchNotifications();
  }
}