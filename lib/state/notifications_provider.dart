import 'package:flutter/foundation.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromApi(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationsProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      // في التطبيق الحقيقي، نحتاج إلى استدعاء API هنا
      notifyListeners();
    }
  }

  void markAllAsRead() {
    // في التطبيق الحقيقي، نحتاج إلى استدعاء API هنا
    notifyListeners();
  }

  void removeNotification(int notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  // Simulated notifications for demo
  void loadDemoNotifications() {
    _notifications = [
      NotificationModel(
        id: 1,
        title: 'طلب جديد',
        message: 'تم استلام طلبك #12345 بنجاح',
        type: 'order',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 2,
        title: 'عرض خاص',
        message: 'خصم 50% على جميع المنتجات',
        type: 'promotion',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 3,
        title: 'تم شحن طلبك',
        message: 'طلبك #12340 في الطريق إليك',
        type: 'order',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    notifyListeners();
  }
}

