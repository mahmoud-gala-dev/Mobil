import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/api_error_handler.dart';

class ProductsProvider extends ChangeNotifier {
  List<CategoryModel> categories = const [];
  List<ProductModel> products = const [];
  List<SliderModel> sliders = const [];
  bool loading = false;
  String? error;

  Future<void> loadInitial() async {
    loading = true;
    error = null;
    notifyListeners();
    
    try {
      // تحميل السلايدرات والأقسام والمنتجات بشكل متوازي
      final results = await Future.wait([
        ApiService.I.getSliders().catchError((e) {
          if (kDebugMode) {
            print('⚠️ [ProductsProvider] خطأ في تحميل السلايدرات: $e');
            print('   📝 الرسالة: ${ApiErrorHandler.getShortMessage(e)}');
          }
          return <SliderModel>[];
        }),
        ApiService.I.categories().catchError((e) {
          if (kDebugMode) {
            print('⚠️ [ProductsProvider] خطأ في تحميل الأقسام: $e');
            print('   📝 الرسالة: ${ApiErrorHandler.getShortMessage(e)}');
          }
          return <CategoryModel>[];
        }),
        ApiService.I.featured().catchError((e) {
          if (kDebugMode) {
            print('⚠️ [ProductsProvider] خطأ في تحميل المنتجات: $e');
            print('   📝 الرسالة: ${ApiErrorHandler.getShortMessage(e)}');
          }
          return <ProductModel>[];
        }),
      ]);
      
      sliders = results[0] as List<SliderModel>;
      categories = results[1] as List<CategoryModel>;
      products = results[2] as List<ProductModel>;
      
      // Debug: طباعة معلومات الصور
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📊 ملخص البيانات المحملة');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        print('✅ السلايدرات: ${sliders.length}');
        if (sliders.isNotEmpty) {
          print('   └─ أول سلايدر: ${sliders[0].title ?? "بدون عنوان"}');
          print('   └─ الصورة: ${sliders[0].image ?? "لا توجد"}');
          print('   └─ الزر: ${sliders[0].buttonText ?? "لا يوجد"}');
        }
        
        print('\n✅ الأقسام: ${categories.length}');
        if (categories.isNotEmpty) {
          print('   └─ أول قسم: ${categories[0].name}');
          print('   └─ الصورة: ${categories[0].image}');
        }
        
        print('\n✅ المنتجات: ${products.length}');
        if (products.isNotEmpty) {
          print('   └─ أول منتج: ${products[0].name}');
          print('   └─ الصورة: ${products[0].image}');
          print('   └─ السعر: ${products[0].price}');
        }
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
      
      error = null;
    } catch (e, stackTrace) {
      // استخدام ApiErrorHandler للحصول على رسالة خطأ واضحة
      error = ApiErrorHandler.getShortMessage(e);
      sliders = const [];
      categories = const [];
      products = const [];
      
      // طباعة الخطأ في وضع التطوير
      if (kDebugMode) {
        print('❌ [ProductsProvider] خطأ في loadInitial: $e');
        print('   📝 الرسالة: $error');
        print('Stack trace: $stackTrace');
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategory(String slug) async {
    loading = true;
    error = null;
    notifyListeners();
    
    try {
      products = await ApiService.I.categoryProducts(slug);
      error = null;
    } catch (e, stackTrace) {
      // استخدام ApiErrorHandler للحصول على رسالة خطأ واضحة
      error = ApiErrorHandler.getShortMessage(e);
      products = const [];
      
      // طباعة الخطأ في وضع التطوير
      if (kDebugMode) {
        print('❌ [ProductsProvider] خطأ في loadCategory: $e');
        print('   📝 الرسالة: $error');
        print('Stack trace: $stackTrace');
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
