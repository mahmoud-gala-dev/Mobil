import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// خدمة رسائل التوست للتطبيق
class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  /// عرض رسالة نجاح
  void showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF16A34A),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 1,
    );
    print('✅ [ToastService] عرض رسالة نجاح: $message');
  }

  /// عرض رسالة خطأ
  void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 1,
    );
    print('❌ [ToastService] عرض رسالة خطأ: $message');
  }

  /// عرض رسالة معلومات
  void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF2563EB),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 1,
    );
    print('ℹ️ [ToastService] عرض رسالة معلومات: $message');
  }

  /// عرض رسالة تحذير
  void showWarning(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFFF59E0B),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 1,
    );
    print('⚠️ [ToastService] عرض رسالة تحذير: $message');
  }

  /// عرض رسالة مخصصة عند إضافة منتج للسلة
  void showAddToCart(String productName) {
    Fluttertoast.showToast(
      msg: '🛒 تم إضافة "$productName" للسلة',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF16A34A),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
    print('🛒 [ToastService] تم إضافة للسلة: $productName');
  }

  /// عرض رسالة مخصصة عند إضافة منتج للمفضلة
  void showAddToFavorite(String productName) {
    Fluttertoast.showToast(
      msg: '❤️ تم إضافة "$productName" للمفضلة',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
    print('❤️ [ToastService] تم إضافة للمفضلة: $productName');
  }

  /// عرض رسالة مخصصة عند إزالة منتج من المفضلة
  void showRemoveFromFavorite(String productName) {
    Fluttertoast.showToast(
      msg: '💔 تم إزالة "$productName" من المفضلة',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[600]!,
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
    print('💔 [ToastService] تم إزالة من المفضلة: $productName');
  }
}

