import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../models/models.dart';
import '../services/sound_service.dart';
import '../services/toast_service.dart';

/// خدمة مساعدة للتعامل مع عمليات السلة مع التحقق من تسجيل الدخول
class CartHelper {
  CartHelper._();

  /// إضافة منتج للسلة مع التحقق من تسجيل الدخول
  /// يعيد true إذا تمت الإضافة بنجاح، false إذا تم التوجيه لصفحة تسجيل الدخول
  static Future<bool> addToCart(
    BuildContext context,
    ProductModel product, {
    int quantity = 1,
    bool showToast = true,
    bool playSound = true,
  }) async {
    final auth = context.read<AuthProvider>();

    // التحقق من تسجيل الدخول
    if (!auth.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return false;
    }

    try {
      final cart = context.read<CartProvider>();
      await cart.add(product, qty: quantity);

      // تشغيل الصوت
      if (playSound) {
        await SoundService().playAddToCartSound();
      }

      // عرض رسالة التوست
      if (showToast) {
        ToastService().showAddToCart(product.name);
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        // تحليل رسالة الخطأ
        final errorMessage = _parseErrorMessage(e.toString());
        _showErrorDialog(context, errorMessage);
      }
      return false;
    }
  }

  /// تحليل رسالة الخطأ واستخراج الرسالة المناسبة
  static String _parseErrorMessage(String error) {
    // التحقق من أخطاء المخزون
    if (error.contains('غير متوفرة في المخزون') ||
        error.contains('out of stock') ||
        error.contains('الكمية المطلوبة')) {
      return 'الكمية المطلوبة غير متوفرة في المخزون';
    }

    // التحقق من أخطاء الاتصال
    if (error.contains('SocketException') ||
        error.contains('Connection') ||
        error.contains('timeout')) {
      return 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت';
    }

    // التحقق من أخطاء المصادقة
    if (error.contains('401') || error.contains('Unauthenticated')) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
    }

    // رسالة افتراضية
    return error.replaceAll('Exception:', '').trim();
  }

  /// عرض نافذة حوار الخطأ
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تعذر إضافة المنتج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة المخزون
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(message),
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حسناً'),
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على أيقونة مناسبة للخطأ
  static IconData _getErrorIcon(String message) {
    if (message.contains('المخزون') || message.contains('الكمية')) {
      return Icons.inventory_2_outlined;
    }
    if (message.contains('الاتصال') || message.contains('الإنترنت')) {
      return Icons.wifi_off_rounded;
    }
    if (message.contains('الجلسة') || message.contains('الدخول')) {
      return Icons.lock_outline_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  /// إضافة عرض للسلة مع التحقق من تسجيل الدخول
  static Future<bool> addOfferToCart(
    BuildContext context, {
    required int offerId,
    int? productId,
    required String title,
    required String image,
    required double price,
    double? originalPrice,
    int quantity = 1,
  }) async {
    final auth = context.read<AuthProvider>();

    // التحقق من تسجيل الدخول
    if (!auth.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return false;
    }

    // إنشاء نموذج المنتج من بيانات العرض
    final product = ProductModel(
      id: productId ?? offerId,
      name: title,
      image: image,
      price: price,
      originalPrice: originalPrice,
      rating: 0.0,
      category: '',
      supplier: '',
    );

    return addToCart(context, product, quantity: quantity);
  }

  /// عرض نافذة تسجيل الدخول المطلوب
  static void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.login_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تسجيل الدخول مطلوب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة السلة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لإضافة المنتجات إلى سلة التسوق،\nيرجى تسجيل الدخول أولاً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('لاحقاً'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/auth/customer/login');
                  },
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('تسجيل الدخول'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// التحقق من حالة تسجيل الدخول فقط (بدون إضافة للسلة)
  static bool checkAuthentication(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showLoginRequiredDialog(context);
      return false;
    }
    return true;
  }
}
