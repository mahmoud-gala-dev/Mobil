import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AddressesProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _addresses.length;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final addressesData = await ApiService.I.getAddresses();
      _addresses = addressesData
          .map((data) => AddressModel.fromApi(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required String label,
    required String address,
    String? city,
    String? governorate,
  }) async {
    try {
      await ApiService.I.createAddress({
        'label': label,
        'address': address,
        if (city != null) 'city': city,
        if (governorate != null) 'governorate': governorate,
      });
      await loadAddresses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress({
    required int addressId,
    required String label,
    required String address,
    String? city,
    String? governorate,
  }) async {
    try {
      await ApiService.I.updateAddress(addressId, {
        'label': label,
        'address': address,
        if (city != null) 'city': city,
        if (governorate != null) 'governorate': governorate,
      });
      await loadAddresses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(int addressId) async {
    try {
      await ApiService.I.deleteAddress(addressId);
      _addresses.removeWhere((a) => a.id == addressId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(int addressId) async {
    try {
      await ApiService.I.setDefaultAddress(addressId);
      await loadAddresses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

