import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'shared_preferences_service.dart';

class CacheService {
  static const String _prefix = 'cache_';
  static const Duration _defaultTTL = Duration(hours: 1);
  
  static CacheService? _instance;

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    await SharedPreferencesService.instance.init();
  }

  // Save data to cache with TTL (Time To Live)
  Future<bool> save<T>(
    String key,
    T data, {
    Duration? ttl,
  }) async {
    try {
      final cacheKey = _prefix + key;
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': (ttl ?? _defaultTTL).inMilliseconds,
      };
      
      final jsonString = jsonEncode(cacheData);
      return await SharedPreferencesService.instance.setString(cacheKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CacheService] خطأ في حفظ Cache: $e');
      }
      return false;
    }
  }

  // Get data from cache
  T? get<T>(String key) {
    try {
      final cacheKey = _prefix + key;
      final jsonString = SharedPreferencesService.instance.getString(cacheKey);
      
      if (jsonString == null) return null;
      
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final ttl = cacheData['ttl'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      if (now - timestamp > ttl) {
        delete(key);
        return null;
      }
      
      return cacheData['data'] as T;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CacheService] خطأ في قراءة Cache: $e');
      }
      return null;
    }
  }

  // Delete specific cache
  Future<bool> delete(String key) async {
    try {
      final cacheKey = _prefix + key;
      return await SharedPreferencesService.instance.remove(cacheKey);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CacheService] خطأ في حذف Cache: $e');
      }
      return false;
    }
  }

  // Clear all cache
  Future<bool> clearAll() async {
    try {
      final keys = SharedPreferencesService.instance.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_prefix));
      
      for (final key in cacheKeys) {
        await SharedPreferencesService.instance.remove(key);
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CacheService] خطأ في مسح جميع Cache: $e');
      }
      return false;
    }
  }

  // Check if cache exists and is valid
  bool has(String key) {
    try {
      final cacheKey = _prefix + key;
      final jsonString = SharedPreferencesService.instance.getString(cacheKey);
      
      if (jsonString == null) return false;
      
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final ttl = cacheData['ttl'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return now - timestamp <= ttl;
    } catch (e) {
      return false;
    }
  }

  // Get cache size in bytes
  int getCacheSize() {
    try {
      int totalSize = 0;
      final keys = SharedPreferencesService.instance.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_prefix));
      
      for (final key in cacheKeys) {
        final value = SharedPreferencesService.instance.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Get cache count
  int getCacheCount() {
    try {
      final keys = SharedPreferencesService.instance.getKeys();
      return keys.where((k) => k.startsWith(_prefix)).length;
    } catch (e) {
      return 0;
    }
  }
}

// Cache Keys Constants
class CacheKeys {
  static const String featuredProducts = 'featured_products';
  static const String categories = 'categories';
  static const String offers = 'offers';
  static const String vendors = 'vendors';
  static const String cart = 'cart';
  static const String wishlist = 'wishlist';
  static const String userProfile = 'user_profile';
  static const String settings = 'settings';
  
  static String productDetails(int id) => 'product_$id';
  static String categoryProducts(String slug) => 'category_products_$slug';
  static String vendorDetails(int id) => 'vendor_$id';
  static String offerDetails(int id) => 'offer_$id';
}

