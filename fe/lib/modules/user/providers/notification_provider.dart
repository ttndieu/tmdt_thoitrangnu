// lib/modules/user/providers/notification_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _notifications = [];
  String _currentFilter = 'all';
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  String get selectedFilter => _currentFilter;

  // ✅ FETCH NOTIFICATIONS (Backend đã filter voucher/promotion)
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('\n📡 ========== FETCH NOTIFICATIONS ==========');
      
      final response = await _apiClient.get(ApiConfig.NOTIFICATIONS);

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Parse notifications
        if (data['notifications'] != null && data['notifications'] is List) {
          _allNotifications = (data['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          
          print('📊 Loaded ${_allNotifications.length} notifications');
          
          // Apply current filter
          _applyFilter(_currentFilter);
          
          // ✅ LẤY UNREAD COUNT TỪ API
          if (data.containsKey('unreadCount')) {
            _unreadCount = data['unreadCount'] is int 
                ? data['unreadCount'] 
                : int.tryParse(data['unreadCount'].toString()) ?? 0;
          } else {
            // Fallback: count from list
            _unreadCount = _allNotifications.where((n) => !n.isRead).length;
          }
          
          print('🔔 Unread count: $_unreadCount');
          
          // Debug: Show notification types
          final typeCounts = <String, int>{};
          for (var n in _allNotifications) {
            final typeStr = n.type.toString().split('.').last;
            typeCounts[typeStr] = (typeCounts[typeStr] ?? 0) + 1;
          }
          print('📋 Types: $typeCounts');
          
        } else {
          print('⚠️ No notifications in response');
          _allNotifications = [];
          _applyFilter(_currentFilter);
          _unreadCount = 0;
        }
        
        print('📡 ========== FETCH NOTIFICATIONS END ==========\n');
      }
    } catch (e) {
      _error = 'Không thể tải thông báo';
      print('❌ Fetch notifications error: $e\n');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ APPLY FILTER
  void _applyFilter(String filter) {
    _currentFilter = filter;
    
    if (filter == 'all') {
      _notifications = _allNotifications;
    } else {
      NotificationType? filterType;
      switch (filter) {
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
      
      if (filterType != null) {
        _notifications = _allNotifications
            .where((n) => n.type == filterType)
            .toList();
      } else {
        _notifications = _allNotifications;
      }
    }
  }

  // ✅ SET FILTER
  void setFilter(String filter) {
    print('🔄 Filter changed: $filter');
    _applyFilter(filter);
    notifyListeners();
  }

  // ✅ GET COUNT BY TYPE
  int getCountByType(String type) {
    if (type == 'all') return _allNotifications.length;
    
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

    if (filterType == null) return 0;
    
    return _allNotifications.where((n) => n.type == filterType).length;
  }

  // ✅ CHECK UNREAD BY TYPE
  bool hasUnreadByType(String type) {
    if (type == 'all') {
      return _allNotifications.any((n) => !n.isRead);
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

    if (filterType == null) return false;
    
    return _allNotifications.any((n) => n.type == filterType && !n.isRead);
  }

  // ✅ MARK AS READ
  Future<void> markAsRead(String notificationId) async {
    try {
      print('\n📝 ========== MARK AS READ ==========');
      print('📝 Notification ID: $notificationId');
      
      // Find notification
      final index = _allNotifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) {
        print('❌ Notification not found');
        print('📝 ========== MARK AS READ END ==========\n');
        return;
      }
      
      final notification = _allNotifications[index];
      
      // Skip if already read
      if (notification.isRead) {
        print('ℹ️ Already read, skipping');
        print('📝 ========== MARK AS READ END ==========\n');
        return;
      }
      
      print('📝 Title: "${notification.title}"');
      print('📝 Type: ${notification.type}');
      
      // Call API
      final response = await _apiClient.put(
        ApiConfig.notificationRead(notificationId),
      );

      if (response.statusCode == 200) {
        // Update in memory
        _allNotifications[index] = _allNotifications[index].copyWith(isRead: true);
        
        // Decrease unread count
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        
        // Re-apply filter
        _applyFilter(_currentFilter);
        
        print('✅ Marked as read');
        print('🔔 New unread count: $_unreadCount');
        print('📝 ========== MARK AS READ END ==========\n');
        
        notifyListeners();
      }
    } catch (e) {
      print('❌ Mark as read error: $e\n');
      // Don't throw - just log
    }
  }

  // ✅ MARK ALL AS READ
  Future<void> markAllAsRead() async {
    try {
      print('\n📝 ========== MARK ALL AS READ ==========');
      
      final response = await _apiClient.put(
        ApiConfig.NOTIFICATIONS_READ_ALL,
      );

      if (response.statusCode == 200) {
        // Update all notifications
        _allNotifications = _allNotifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        
        // Reset unread count
        _unreadCount = 0;
        
        // Re-apply filter
        _applyFilter(_currentFilter);
        
        print('✅ Marked all as read');
        print('📝 ========== MARK ALL AS READ END ==========\n');
        
        notifyListeners();
      }
    } catch (e) {
      print('❌ Mark all as read error: $e\n');
      throw e; // Re-throw for UI to handle
    }
  }

  // ✅ DELETE NOTIFICATION
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('\n🗑️ ========== DELETE NOTIFICATION ==========');
      print('🗑️ Notification ID: $notificationId');
      
      final response = await _apiClient.delete(
        ApiConfig.deleteNotification(notificationId),
      );

      if (response.statusCode == 200) {
        // Find and check if unread
        final notification = _allNotifications.firstWhere(
          (n) => n.id == notificationId,
          orElse: () => throw Exception('Notification not found'),
        );
        
        final wasUnread = !notification.isRead;
        
        // Remove from list
        _allNotifications.removeWhere((n) => n.id == notificationId);
        
        // Decrease unread count if was unread
        if (wasUnread && _unreadCount > 0) {
          _unreadCount--;
        }
        
        // Re-apply filter
        _applyFilter(_currentFilter);
        
        print('✅ Deleted');
        print('🔔 New unread count: $_unreadCount');
        print('🗑️ ========== DELETE NOTIFICATION END ==========\n');
        
        notifyListeners();
      }
    } catch (e) {
      print('❌ Delete notification error: $e\n');
      throw e; // Re-throw for UI to handle
    }
  }

  // ✅ FETCH UNREAD COUNT (for badge updates)
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.NOTIFICATIONS_UNREAD_COUNT,
      );

      if (response.statusCode == 200) {
        final count = response.data['count'];
        _unreadCount = count is int 
            ? count 
            : int.tryParse(count.toString()) ?? 0;
        
        print('🔔 Updated unread count: $_unreadCount');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Fetch unread count error: $e');
      // Don't throw - just log
    }
  }

  // REFRESH
  Future<void> refresh() async {
    await fetchNotifications();
  }

  // CLEAR ERROR
  void clearError() {
    _error = null;
    notifyListeners();
  }
}