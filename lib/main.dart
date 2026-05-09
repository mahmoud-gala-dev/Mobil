import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'elite_one_app.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/products_provider.dart';
import 'state/favorites_provider.dart';
import 'state/theme_provider.dart';
import 'state/app_settings_provider.dart';
import 'services/shared_preferences_service.dart';
import 'features/payment/state/payment_provider.dart';

void main() async {
  // تهيئة Flutter Binding أولاً
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة SharedPreferences قبل إنشاء Providers
  // هذا يضمن أن جميع Providers يمكنها قراءة البيانات عند إنشائها
  if (kDebugMode) {
    print('🚀 [main] بدء تهيئة SharedPreferences...');
  }

  try {
    final success = await SharedPreferencesService.instance.init();
    if (kDebugMode) {
      if (success) {
        print('✅ [main] تم تهيئة SharedPreferences بنجاح');
      } else {
        print(
            '⚠️ [main] فشل تهيئة SharedPreferences - سيتم استخدام قيم افتراضية');
        print('💡 [main] سيتم إعادة المحاولة عند الحاجة');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ [main] خطأ غير متوقع في تهيئة SharedPreferences: $e');
    }
  }

  // إنشاء التطبيق بعد تهيئة SharedPreferences
  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductsProvider()..loadInitial()),
      ChangeNotifierProvider(create: (_) => FavoritesProvider()..refresh()),
      ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ChangeNotifierProvider(
          create: (_) => AppSettingsProvider()..fetchSettings()),
    ],
    child: const EliteOneApp(),
  );

  runApp(app);
}
