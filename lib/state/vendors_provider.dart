import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class VendorsProvider with ChangeNotifier {
  List<VendorModel> _vendors = [];
  bool _isLoading = false;
  String? _error;

  List<VendorModel> get vendors => _vendors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vendorsData = await ApiService.I.vendors();
      _vendors = vendorsData
          .map((data) => VendorModel.fromApi(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vendorsData = await ApiService.I.featuredVendors();
      _vendors = vendorsData
          .map((data) => VendorModel.fromApi(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  VendorModel? getVendorById(int id) {
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }
}

