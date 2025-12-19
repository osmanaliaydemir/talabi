import 'package:flutter/material.dart';
import 'package:mobile/features/notifications/data/models/customer_notification.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CustomerNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notifications = await _apiService.getCustomerNotifications();
      _notifications = List<CustomerNotification>.from(notifications);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      await _apiService.markNotificationAsRead('customer', notificationId);
    } catch (e, stackTrace) {
      // Revert optimistic update if API call fails
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        notifyListeners();
      }
      LoggerService().error(
        'Error marking notification as read',
        e,
        stackTrace,
      );
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final originalNotifications = List<CustomerNotification>.from(
      _notifications,
    );
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _apiService.markAllNotificationsAsRead('customer');
    } catch (e, stackTrace) {
      // Revert optimistic update if API call fails
      _notifications = originalNotifications;
      notifyListeners();
      LoggerService().error(
        'Error marking all notifications as read',
        e,
        stackTrace,
      );
    }
  }
}
