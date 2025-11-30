import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class OrdersProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _orders.length;

  Future<void> loadRecentOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ordersData = await ApiService.I.recentOrders();
      _orders = ordersData
          .map((data) => OrderModel.fromApi(data as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> trackOrder(String orderNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderData = await ApiService.I.trackOrder(orderNumber);
      final order = OrderModel.fromApi(orderData);
      _currentOrder = order;
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderConfirmation(String orderNumber) async {
    try {
      return await ApiService.I.orderConfirmation(orderNumber);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      return await ApiService.I.orderDetails(orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  OrderModel? getOrderByNumber(String orderNumber) {
    try {
      return _orders.firstWhere((o) => o.orderNumber == orderNumber);
    } catch (e) {
      return null;
    }
  }

  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((o) => o.status == status).toList();
  }

  // Filter methods
  List<OrderModel> get pendingOrders => getOrdersByStatus('pending');
  List<OrderModel> get processingOrders => getOrdersByStatus('processing');
  List<OrderModel> get completedOrders => getOrdersByStatus('completed');
  List<OrderModel> get cancelledOrders => getOrdersByStatus('cancelled');
}

