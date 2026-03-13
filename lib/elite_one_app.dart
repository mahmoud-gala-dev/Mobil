import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'state/theme_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/categories_screen.dart';
import 'ui/screens/category_screen.dart';
import 'ui/screens/product_details_screen.dart';
import 'ui/screens/cart_screen.dart';
import 'ui/screens/checkout_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/favorites_screen.dart';
import 'ui/screens/order_track_screen.dart';
import 'ui/screens/orders_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/register_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/offers_screen.dart';
import 'ui/screens/offer_details_screen.dart';
import 'ui/screens/vendors_screen.dart';
import 'ui/screens/auth/customer_login_screen.dart';
import 'ui/screens/auth/customer_register_screen.dart';
import 'ui/screens/auth/vendor_login_screen.dart';
import 'ui/screens/auth/vendor_register_screen.dart';
import 'ui/screens/dashboard/customer_dashboard.dart';
import 'ui/screens/dashboard/vendor_dashboard.dart';
import 'ui/screens/vendor/vendor_add_product_screen.dart';
import 'ui/screens/vendor/vendor_orders_screen.dart';
import 'ui/screens/vendor_details_screen.dart';
import 'ui/screens/static_page_screen.dart';
import 'ui/screens/static_pages_list_screen.dart';
import 'ui/screens/payment_result_screen.dart';
import 'ui/screens/payment_webview_screen.dart';

class EliteOneApp extends StatelessWidget {
  const EliteOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // مراقبة حالة الثيم
    final themeProvider = context.watch<ThemeProvider>();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
        GoRoute(
          path: '/category/:slug',
          builder: (_, s) => CategoryScreen(slug: s.pathParameters['slug']!),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (_, s) {
            final idParam = s.pathParameters['id'];
            if (idParam == null) {
              return const Scaffold(body: Center(child: Text('خطأ: معرف المنتج مفقود')));
            }
            final productId = int.tryParse(idParam);
            if (productId == null) {
              return Scaffold(
                body: Center(
                  child: Text('خطأ: معرف المنتج غير صالح: $idParam'),
                ),
              );
            }
            return ProductDetailsScreen(id: productId);
          },
        ),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
        GoRoute(
          path: '/offer/:id',
          builder: (_, s) {
            final idParam = s.pathParameters['id'];
            if (idParam == null) {
              return const Scaffold(body: Center(child: Text('خطأ: معرف العرض مفقود')));
            }
            final offerId = int.tryParse(idParam);
            if (offerId == null) {
              return Scaffold(
                body: Center(
                  child: Text('خطأ: معرف العرض غير صالح: $idParam'),
                ),
              );
            }
            return OfferDetailsScreen(offerId: offerId);
          },
        ),
        GoRoute(path: '/vendors', builder: (_, __) => const VendorsScreen()),
        // Vendor Dashboard Routes - يجب أن يكون قبل /vendor/:id
        GoRoute(path: '/vendor/dashboard', builder: (_, __) => const VendorDashboard()),
        GoRoute(path: '/vendor/add-product', builder: (_, __) => const VendorAddProductScreen()),
        GoRoute(path: '/vendor/orders', builder: (_, __) => const VendorOrdersScreen()),
        GoRoute(
          path: '/vendor/:id',
          builder: (_, s) {
            final idParam = s.pathParameters['id'];
            if (idParam == null) {
              return const Scaffold(body: Center(child: Text('خطأ: معرف المتجر مفقود')));
            }
            final vendorId = int.tryParse(idParam);
            if (vendorId == null) {
              return Scaffold(
                body: Center(
                  child: Text('خطأ: معرف المتجر غير صالح: $idParam'),
                ),
              );
            }
            return VendorDetailsScreen(vendorId: vendorId);
          },
        ),
        GoRoute(
          path: '/order-track/:num',
          builder: (_, s) => OrderTrackScreen(orderNumber: s.pathParameters['num']!),
        ),
        GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/addresses', builder: (_, __) => const ProfileScreen(initialTab: 1)),
        
        // Customer Auth Routes
        GoRoute(path: '/auth/customer/login', builder: (_, __) => const CustomerLoginScreen()),
        GoRoute(path: '/auth/customer/register', builder: (_, __) => const CustomerRegisterScreen()),
        
        // Vendor Auth Routes
        GoRoute(path: '/auth/vendor/login', builder: (_, __) => const VendorLoginScreen()),
        GoRoute(path: '/auth/vendor/register', builder: (_, __) => const VendorRegisterScreen()),
        
        // Static Pages Routes
        GoRoute(path: '/static-pages', builder: (_, __) => const StaticPagesListScreen()),
        GoRoute(
          path: '/static-page/:slug',
          builder: (_, s) {
            final slug = s.pathParameters['slug'];
            if (slug == null) {
              return const Scaffold(body: Center(child: Text('خطأ: معرف الصفحة مفقود')));
            }
            return StaticPageScreen(slug: slug);
          },
        ),
        // Static pages - old routes (kept for compatibility)
        GoRoute(path: '/terms', builder: (_, __) => const StaticPageScreen(slug: 'terms')),
        GoRoute(path: '/privacy', builder: (_, __) => const StaticPageScreen(slug: 'privacy')),
        
        // Static pages - new routes used by Footer
        GoRoute(path: '/privacy-policy', builder: (_, __) => const StaticPageScreen(slug: 'privacy')),
        GoRoute(path: '/terms-conditions', builder: (_, __) => const StaticPageScreen(slug: 'terms')),
        GoRoute(path: '/return-policy', builder: (_, __) => const StaticPageScreen(slug: 'refund')),
        GoRoute(path: '/faq', builder: (_, __) => const StaticPageScreen(slug: 'faq')),
        GoRoute(path: '/about-us', builder: (_, __) => const StaticPageScreen(slug: 'about')),
        
        // Dashboard Routes
        GoRoute(path: '/customer/dashboard', builder: (_, __) => const CustomerDashboard()),

        // Payment Routes - مسارات الدفع
        GoRoute(
          path: '/payment/result',
          builder: (_, s) {
            final result = s.uri.queryParameters['result'];
            final orderId = int.tryParse(s.uri.queryParameters['orderId'] ?? '');
            final transactionId = int.tryParse(s.uri.queryParameters['tx'] ?? '');
            final errorCode = s.uri.queryParameters['err'];
            return PaymentResultScreen(
              result: result,
              orderId: orderId,
              transactionId: transactionId,
              errorCode: errorCode,
            );
          },
        ),
        GoRoute(
          path: '/payment/webview',
          builder: (_, s) {
            final url = Uri.decodeComponent(s.uri.queryParameters['url'] ?? '');
            final orderId = int.tryParse(s.uri.queryParameters['orderId'] ?? '') ?? 0;
            final transactionId = int.tryParse(s.uri.queryParameters['tx'] ?? '') ?? 0;
            if (url.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('خطأ: رابط الدفع مفقود')),
              );
            }
            return PaymentWebViewScreen(
              paymentUrl: url,
              orderId: orderId,
              transactionId: transactionId,
            );
          },
        ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        title: 'Engeb - متجرك الإلكتروني',
        // استخدام الثيم الأصلي من AppTheme مع دعم الوضع المظلم
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: themeProvider.themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar')],
        locale: const Locale('ar'),
      ),
    );
  }
}
