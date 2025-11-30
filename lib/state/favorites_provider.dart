import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<int> _ids = {};
  Set<int> get ids => _ids;

  Future<void> refresh() async {
    final data = await ApiService.I.wishlist();
    final List ids = data['ids'] as List? ?? [];
    _ids
      ..clear()
      ..addAll(ids.cast<int>());
    notifyListeners();
  }

  Future<bool> toggle(int id) async {
    if (_ids.contains(id)) {
      await ApiService.I.removeWishlist(id);
      _ids.remove(id);
      notifyListeners();
      return false;
    } else {
      await ApiService.I.addWishlist(id);
      _ids.add(id);
      notifyListeners();
      return true;
    }
  }

  bool isFav(int id) => _ids.contains(id);
}
