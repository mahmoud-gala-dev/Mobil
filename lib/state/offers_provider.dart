import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class OffersProvider with ChangeNotifier {
  List<OfferModel> _offers = [];
  bool _isLoading = false;
  String? _error;

  List<OfferModel> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _offers.length;

  Future<void> loadOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final offersData = await ApiService.I.offers();
      _offers = offersData
          .map((data) => OfferModel.fromApi(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final offersData = await ApiService.I.featuredOffers();
      _offers = offersData
          .map((data) => OfferModel.fromApi(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFlashSaleOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final offersData = await ApiService.I.flashSaleOffers();
      _offers = offersData
          .map((data) => OfferModel.fromApi(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  OfferModel? getOfferById(int id) {
    try {
      return _offers.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  List<OfferModel> get activeOffers {
    final now = DateTime.now();
    return _offers.where((offer) {
      if (offer.endDate == null) return true;
      return offer.endDate!.isAfter(now);
    }).toList();
  }
}

