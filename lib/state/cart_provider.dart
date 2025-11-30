import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CartItem {
  final ProductModel product;
  int qty;
  CartItem(this.product, this.qty);
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  Map<int, CartItem> get items => _items;

  Future<void> refresh() async {
    final data = await ApiService.I.cart();
    _items.clear();
    final List items = data['items'] as List? ?? [];
    for (final e in items) {
      final p = ProductModel.fromApi({
        'id': e['id'],
        'name': e['name'],
        'image': e['image'],
        'price': e['price'],
        'original_price': e['original_price'],
        'rating': 0,
        'category': '',
        'vendor': e['vendor'] != null ? {'name': e['vendor']['name']} : null,
      });
      _items[p.id] = CartItem(p, (e['quantity'] as num).toInt());
    }
    notifyListeners();
  }

  Future<void> add(ProductModel p, {int qty = 1}) async {
    await ApiService.I.addToCart(p.id, quantity: qty);
    await refresh();
  }

  Future<void> remove(int id) async {
    await ApiService.I.removeFromCart(id);
    await refresh();
  }

  Future<void> setQty(int id, int qty) async {
    await ApiService.I.updateCart(id, qty);
    await refresh();
  }

  Future<void> clear() async {
    await ApiService.I.clearCart();
    await refresh();
  }

  double get subtotal => _items.values
      .fold(0.0, (s, e) => s + e.product.price * e.qty);
}
