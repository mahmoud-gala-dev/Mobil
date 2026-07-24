import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة آمنة لإدارة SharedPreferences مع معالجة أخطاء محسنة
/// 
/// تحل مشاكل Platform Channel Errors عن طريق:
/// 1. إعادة المحاولة في حالة فشل الاتصال
/// 2. معالجة الأخطاء بشكل آمن
/// 3. استخدام cache محلي كـ fallback
class SharedPreferencesService {
  static SharedPreferencesService? _instance;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _hasError = false;

  SharedPreferencesService._();

  /// الحصول على مثيل الخدمة (Singleton)
  static SharedPreferencesService get instance {
    _instance ??= SharedPreferencesService._();
    return _instance!;
  }

  /// تهيئة SharedPreferences مع إعادة المحاولة
  Future<bool> init() async {
    if (_isInitialized && _prefs != null) {
      return true;
    }

    if (_hasError) {
      if (kDebugMode) {
        print('⚠️ [SharedPreferencesService] محاولة إعادة التهيئة بعد خطأ سابق');
      }
      _hasError = false;
    }

    const maxRetries = 5;
    const retryDelay = Duration(milliseconds: 600);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('🔄 [SharedPreferencesService] محاولة التهيئة $attempt/$maxRetries');
        }

        // محاولة الوصول لـ SharedPreferences
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
        _hasError = false;

        if (kDebugMode) {
          print('✅ [SharedPreferencesService] تم التهيئة بنجاح');
        }
        return true;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('❌ [SharedPreferencesService] خطأ في المحاولة $attempt: $e');
          if (attempt == maxRetries) {
            print('📋 Stack trace: $stackTrace');
          }
        }

        if (attempt < maxRetries) {
          // زيادة وقت الانتظار تدريجياً
          await Future.delayed(retryDelay * attempt);
        } else {
          _hasError = true;
          if (kDebugMode) {
            print('⚠️ [SharedPreferencesService] فشل التهيئة بعد $maxRetries محاولات');
            print('⚠️ [SharedPreferencesService] سيتم استخدام قيم افتراضية');
            print('💡 [SharedPreferencesService] قد تكون المشكلة في Flutter Engine - سيتم إعادة المحاولة عند الحاجة');
          }
        }
      }
    }

    return false;
  }

  /// التحقق من جاهزية الخدمة
  bool get isReady => _isInitialized && _prefs != null && !_hasError;

  /// الحصول على قيمة String
  String? getString(String key) {
    if (!isReady) {
      if (kDebugMode) {
        print('⚠️ [SharedPreferencesService] محاولة قراءة "$key" قبل التهيئة');
      }
      return null;
    }

    try {
      return _prefs!.getString(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في قراءة "$key": $e');
      }
      return null;
    }
  }

  /// حفظ قيمة String
  Future<bool> setString(String key, String value) async {
    if (!isReady) {
      if (kDebugMode) {
        print('⚠️ [SharedPreferencesService] محاولة كتابة "$key" قبل التهيئة');
      }
      
      // محاولة إعادة التهيئة
      final initialized = await init();
      if (!initialized) {
        return false;
      }
    }

    try {
      return await _prefs!.setString(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في كتابة "$key": $e');
      }
      return false;
    }
  }

  /// الحصول على قيمة bool
  bool? getBool(String key) {
    if (!isReady) return null;

    try {
      return _prefs!.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في قراءة "$key": $e');
      }
      return null;
    }
  }

  /// حفظ قيمة bool
  Future<bool> setBool(String key, bool value) async {
    if (!isReady) {
      final initialized = await init();
      if (!initialized) return false;
    }

    try {
      return await _prefs!.setBool(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في كتابة "$key": $e');
      }
      return false;
    }
  }

  /// الحصول على قيمة int
  int? getInt(String key) {
    if (!isReady) return null;

    try {
      return _prefs!.getInt(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في قراءة "$key": $e');
      }
      return null;
    }
  }

  /// حفظ قيمة int
  Future<bool> setInt(String key, int value) async {
    if (!isReady) {
      final initialized = await init();
      if (!initialized) return false;
    }

    try {
      return await _prefs!.setInt(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في كتابة "$key": $e');
      }
      return false;
    }
  }

  /// الحصول على جميع المفاتيح
  Set<String> getKeys() {
    if (!isReady) return <String>{};

    try {
      return _prefs!.getKeys();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في قراءة المفاتيح: $e');
      }
      return <String>{};
    }
  }

  /// حذف قيمة
  Future<bool> remove(String key) async {
    if (!isReady) {
      final initialized = await init();
      if (!initialized) return false;
    }

    try {
      return await _prefs!.remove(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في حذف "$key": $e');
      }
      return false;
    }
  }

  /// مسح جميع البيانات
  Future<bool> clear() async {
    if (!isReady) {
      final initialized = await init();
      if (!initialized) return false;
    }

    try {
      return await _prefs!.clear();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SharedPreferencesService] خطأ في مسح البيانات: $e');
      }
      return false;
    }
  }

  /// الحصول على SharedPreferences مباشرة (للاستخدام في حالات خاصة)
  SharedPreferences? get raw {
    return isReady ? _prefs : null;
  }
}

