import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../models/models.dart';
import '../config/api_config.dart';
import 'retry_interceptor.dart';
import 'auth_interceptor.dart';

// استخدام التكوين المركزي
final String kApiBase = ApiConfig.baseUrl;

class ApiService {
  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: kApiBase,
      connectTimeout: const Duration(seconds: ApiConfig.connectionTimeout),
      receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
      headers: ApiConfig.defaultHeaders,
      validateStatus: (s) => s != null && s >= 200 && s < 300,
      followRedirects: false,
    ));

    // إضافة Auth Interceptor لإضافة Bearer Token تلقائياً
    _dio.interceptors.add(AuthInterceptor());

    // إضافة Cookie Manager
    _dio.interceptors.add(CookieManager(CookieJar()));

    // إضافة Retry Interceptor لإعادة المحاولة التلقائية
    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    // إضافة Logger في وضع التطوير
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => print('🌐 API: $obj'),
      ));
    }

    // طباعة معلومات التكوين عند البدء
    ApiConfig.printConfig();
  }
  static final ApiService I = ApiService._();
  late final Dio _dio;

  // ============ PING ============
  Future<Map<String, dynamic>> ping() async {
    final res = await _dio.get('/ping');
    return res.data as Map<String, dynamic>;
  }

  // ============ SEARCH ============
  Future<List<ProductModel>> search(String q) async {
    final res = await _dio.get('/search', queryParameters: {'q': q});
    final List data = res.data['data'] as List;
    return data.map((e) => ProductModel.fromApi(e)).toList();
  }

  Future<List<ProductModel>> searchProducts(String q,
      {Map<String, dynamic>? filters}) async {
    final res = await _dio.get('/search/products', queryParameters: {
      'q': q,
      if (filters != null) ...filters,
    });
    final List data = res.data['data'] as List;
    return data.map((e) => ProductModel.fromApi(e)).toList();
  }

  Future<Map<String, dynamic>> getSearchFilters() async {
    final res = await _dio.get('/search/filters');
    return res.data as Map<String, dynamic>;
  }

  Future<List<String>> getPopularSearches() async {
    final res = await _dio.get('/search/popular');
    final List data = res.data['searches'] as List;
    return data.cast<String>();
  }

  Future<List<String>> autocomplete(String q) async {
    final res =
        await _dio.get('/search/autocomplete', queryParameters: {'q': q});
    final List data = res.data['suggestions'] as List;
    return data.cast<String>();
  }

  // ============ CATEGORIES ============
  Future<List<CategoryModel>> categories() async {
    try {
      final res = await _dio.get('/categories');

      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['categories'] is List) {
        data = res.data['categories'] as List;
      } else {
        print('⚠️ Categories response structure غير متوقع: ${res.data}');
        return [];
      }

      return data
          .map((e) => CategoryModel.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في categories: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> mainCategories() async {
    try {
      final res = await _dio.get('/categories/main');

      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['categories'] is List) {
        data = res.data['categories'] as List;
      } else {
        print('⚠️ Main categories response structure غير متوقع: ${res.data}');
        return [];
      }

      return data
          .map((e) => CategoryModel.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في mainCategories: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> supermarketCategories() async {
    try {
      final res = await _dio.get('/categories/supermarket');

      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['categories'] is List) {
        data = res.data['categories'] as List;
      } else {
        print(
            '⚠️ Supermarket categories response structure غير متوقع: ${res.data}');
        return [];
      }

      return data
          .map((e) => CategoryModel.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في supermarketCategories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> categoryDetails(String slug) async {
    final res = await _dio.get('/categories/$slug');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> categorySubcategories(String slug) async {
    try {
      final res = await _dio.get('/categories/$slug/subcategories');

      if (res.data == null) {
        return [];
      }

      List? data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['subcategories'] is List) {
        data = res.data['subcategories'] as List;
      } else {
        print(
            '⚠️ Category subcategories response structure غير متوقع: ${res.data}');
        return [];
      }

      return data.where((e) => e != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      print('❌ خطأ في categorySubcategories: $e');
      return [];
    }
  }

  Future<List<ProductModel>> categoryProducts(String slug) async {
    try {
      print('🌐 [API] ═══════════════════════════════════');
      print('🌐 [API] طلب منتجات القسم');
      print('🌐 [API] Endpoint: /categories/$slug/products');
      print('🌐 [API] Base URL: $kApiBase');

      final res = await _dio.get('/categories/$slug/products');

      print('📡 [API] Status Code: ${res.statusCode}');
      print('📡 [API] Response Type: ${res.data.runtimeType}');

      // معالجة structures مختلفة من الـ API
      List? data;
      if (res.data == null) {
        print('⚠️ [API] استجابة null من categoryProducts');
        return [];
      } else if (res.data is List) {
        print('📦 [API] Response هو List مباشر');
        data = res.data as List;
      } else if (res.data is Map) {
        print('📦 [API] Response هو Map، البحث عن المنتجات...');
        final responseMap = res.data as Map<String, dynamic>;
        print('📦 [API] Keys في Response: ${responseMap.keys.join(", ")}');

        if (responseMap['success'] == false) {
          print(
              '❌ [API] الطلب فشل: ${responseMap['message'] ?? "unknown error"}');
          throw Exception(
              responseMap['message'] ?? 'فشل جلب المنتجات من الخادم');
        }

        // محاولة إيجاد المنتجات في structures مختلفة
        if (responseMap['data'] is List) {
          print('✅ [API] وجدنا المنتجات في response["data"]');
          data = responseMap['data'] as List;
        } else if (responseMap['products'] is Map &&
            responseMap['products']['data'] is List) {
          print(
              '✅ [API] وجدنا المنتجات في response["products"]["data"] (paginated)');
          data = responseMap['products']['data'] as List;
        } else if (responseMap['products'] is List) {
          print('✅ [API] وجدنا المنتجات في response["products"]');
          data = responseMap['products'] as List;
        } else {
          print('⚠️ [API] Category products response structure غير متوقع');
          print(
              '📦 [API] Response Data: ${responseMap.toString().substring(0, 200)}...');
          return [];
        }
      } else {
        print(
            '⚠️ [API] Category products response type غير معروف: ${res.data.runtimeType}');
        return [];
      }

      print('📊 [API] عدد المنتجات المستلمة: ${data.length}');

      if (data.isEmpty) {
        print('ℹ️ [API] لا توجد منتجات في هذا القسم');
        return [];
      }

      print('🔄 [API] تحويل البيانات إلى ProductModel...');
      final products = data
          .where((e) => e != null)
          .map((e) {
            try {
              return ProductModel.fromApi(e as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [API] فشل تحويل منتج: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .cast<ProductModel>()
          .toList();

      print('✅ [API] تم تحويل ${products.length} منتج بنجاح');
      print('🌐 [API] ═══════════════════════════════════');

      return products;
    } catch (e, stackTrace) {
      print('❌ [API] ═══════════════════════════════════');
      print('❌ [API] خطأ في categoryProducts($slug)');
      print('❌ [API] الخطأ: $e');
      print('❌ [API] Stack trace: $stackTrace');
      print('❌ [API] ═══════════════════════════════════');
      rethrow;
    }
  }

  // ============ SUBCATEGORIES ============
  Future<List<Map<String, dynamic>>> subcategories() async {
    final res = await _dio.get('/subcategories');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> subcategoryDetails(String slug) async {
    final res = await _dio.get('/subcategories/$slug');
    return res.data as Map<String, dynamic>;
  }

  // ============ LOCATIONS ============
  Future<List<Map<String, dynamic>>> governorates() async {
    final res = await _dio.get('/governorates');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> governorateDetails(int id) async {
    final res = await _dio.get('/governorates/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> governorateCities(
      int governorateId) async {
    final res = await _dio.get('/governorates/$governorateId/cities');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> cities() async {
    final res = await _dio.get('/cities');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> cityDetails(int id) async {
    final res = await _dio.get('/cities/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getGovernorates() async {
    final res = await _dio.get('/locations/governorates');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCities({int? governorateId}) async {
    final res = await _dio.get('/locations/cities', queryParameters: {
      if (governorateId != null) 'governorate_id': governorateId,
    });
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ============ BUSINESS CATEGORIES ============
  Future<List<Map<String, dynamic>>> businessCategories() async {
    final res = await _dio.get('/business-categories');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> businessCategoryDetails(int id) async {
    final res = await _dio.get('/business-categories/$id');
    return res.data as Map<String, dynamic>;
  }

  // ============ BRANDS ============
  Future<List<Map<String, dynamic>>> brands() async {
    final res = await _dio.get('/brands');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> brandDetails(int id) async {
    final res = await _dio.get('/brands/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<List<ProductModel>> brandProducts(int brandId) async {
    final res = await _dio.get('/brands/$brandId/products');
    final List data = res.data['data'] as List;
    return data.map((e) => ProductModel.fromApi(e)).toList();
  }

  // ============ CONTACT METHODS ============
  Future<List<Map<String, dynamic>>> contactMethods() async {
    final res = await _dio.get('/contact-methods');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ============ VENDORS ============
  Future<List<Map<String, dynamic>>> vendors(
      {Map<String, dynamic>? filters}) async {
    final res = await _dio.get('/vendors', queryParameters: filters);
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> featuredVendors() async {
    final res = await _dio.get('/vendors/featured');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> vendorDetails(int id) async {
    try {
      print('🏪 [API] جلب تفاصيل المتجر #$id');
      final res = await _dio.get('/vendors/$id');

      // معالجة آمنة للاستجابة
      if (res.data is Map) {
        final responseMap = res.data as Map<String, dynamic>;

        // إذا كانت البيانات في data
        if (responseMap['data'] != null && responseMap['data'] is Map) {
          print('✅ [API] تم جلب تفاصيل المتجر من response["data"]');
          return responseMap['data'] as Map<String, dynamic>;
        }

        // إذا كانت البيانات مباشرة
        print('✅ [API] تم جلب تفاصيل المتجر مباشرة');
        return responseMap;
      }

      print(
          '⚠️ [API] vendor details response type غير متوقع: ${res.data.runtimeType}');
      return {};
    } catch (e) {
      print('❌ [API] خطأ في vendorDetails($id): $e');
      rethrow;
    }
  }

  Future<List<ProductModel>> vendorProducts(int vendorId) async {
    try {
      print('🏪 [API] ═══════════════════════════════════');
      print('🏪 [API] جلب منتجات المتجر #$vendorId');
      print('🏪 [API] Endpoint: /vendors/$vendorId/products');

      final res = await _dio.get('/vendors/$vendorId/products');

      print('📡 [API] Status Code: ${res.statusCode}');
      print('📡 [API] Response Type: ${res.data.runtimeType}');

      // معالجة آمنة للاستجابة
      if (res.data == null) {
        print('⚠️ [API] استجابة null من vendorProducts للمتجر $vendorId');
        return [];
      }

      List<dynamic> data;
      if (res.data is List) {
        print('📦 [API] Response هو List مباشر');
        data = res.data as List<dynamic>;
      } else if (res.data is Map) {
        print('📦 [API] Response هو Map، البحث عن المنتجات...');
        final responseMap = res.data as Map<String, dynamic>;
        print('📦 [API] Keys في Response: ${responseMap.keys.join(", ")}');

        if (responseMap['success'] == false) {
          print(
              '❌ [API] الطلب فشل: ${responseMap['message'] ?? "unknown error"}');
          return [];
        }

        if (responseMap['data'] is List) {
          print('✅ [API] وجدنا المنتجات في response["data"]');
          data = responseMap['data'] as List<dynamic>;
        } else if (responseMap['products'] is List) {
          print('✅ [API] وجدنا المنتجات في response["products"]');
          data = responseMap['products'] as List<dynamic>;
        } else {
          print('⚠️ [API] Vendor products response structure غير متوقع');
          print(
              '📦 [API] Response Data: ${responseMap.toString().substring(0, 200)}...');
          return [];
        }
      } else {
        print(
            '⚠️ [API] Vendor products response type غير معروف: ${res.data.runtimeType}');
        return [];
      }

      print('📊 [API] عدد المنتجات المستلمة: ${data.length}');

      if (data.isEmpty) {
        print('ℹ️ [API] لا توجد منتجات للمتجر $vendorId');
        print('🏪 [API] ═══════════════════════════════════');
        return [];
      }

      print('🔄 [API] تحويل البيانات إلى ProductModel...');
      final products = data
          .where((e) => e != null)
          .map((e) {
            try {
              return ProductModel.fromApi(e as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ [API] فشل تحويل منتج: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .cast<ProductModel>()
          .toList();

      print('✅ [API] تم تحويل ${products.length} منتج بنجاح');
      print('🏪 [API] ═══════════════════════════════════');

      return products;
    } catch (e, stackTrace) {
      print('❌ [API] ═══════════════════════════════════');
      print('❌ [API] خطأ في vendorProducts($vendorId)');
      print('❌ [API] الخطأ: $e');
      print('❌ [API] Stack trace: $stackTrace');
      print('❌ [API] ═══════════════════════════════════');
      return [];
    }
  }

  // ============ PRODUCTS ============
  Future<List<ProductModel>> featured() async {
    try {
      final res = await _dio.get('/products/featured');

      // معالجة structures مختلفة من الـ API
      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['products'] is List) {
        data = res.data['products'] as List;
      } else {
        print('⚠️ Featured response structure غير متوقع: ${res.data}');
        return [];
      }

      return data
          .map((e) => ProductModel.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في featured: $e');
      return [];
    }
  }

  Future<List<ProductModel>> freshProducts() async {
    try {
      final res = await _dio.get('/products/fresh');

      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['products'] is List) {
        data = res.data['products'] as List;
      } else {
        print('⚠️ Fresh products response structure غير متوقع: ${res.data}');
        return [];
      }

      return data
          .map((e) => ProductModel.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في freshProducts: $e');
      return [];
    }
  }

  Future<List<ProductModel>> offerProducts() async {
    try {
      final res = await _dio.get('/products/offers');

      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['products'] is List) {
        data = res.data['products'] as List;
      } else {
        print('⚠️ Offer products response structure غير متوقع: ${res.data}');
        return [];
      }

      return data
          .map((e) => ProductModel.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في offerProducts: $e');
      return [];
    }
  }

  Future<(ProductModel, List<ProductModel>)> productDetails(int id) async {
    final res = await _dio.get('/products/$id');
    final p = ProductModel.fromApi(res.data['product']);
    final List related = res.data['related'] as List;
    return (p, related.map((e) => ProductModel.fromApi(e)).toList());
  }

  // ============ REVIEWS ============
  Future<Map<String, dynamic>> getProductReviews(int productId,
      {int page = 1}) async {
    final res = await _dio
        .get('/products/$productId/reviews', queryParameters: {'page': page});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVendorReviews(int vendorId,
      {int page = 1}) async {
    final res = await _dio
        .get('/vendors/$vendorId/reviews', queryParameters: {'page': page});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductReviewStats(int productId) async {
    final res = await _dio.get('/products/$productId/reviews/stats');
    return res.data as Map<String, dynamic>;
  }

  Future<void> storeProductReview({
    required int productId,
    required int rating,
    String? comment,
    List<String>? images,
  }) async {
    await _dio.post('/reviews/products', data: {
      'product_id': productId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (images != null) 'images': images,
    });
  }

  Future<void> storeVendorReview({
    required int vendorId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post('/reviews/vendors', data: {
      'vendor_id': vendorId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
  }

  Future<void> updateProductReview(int reviewId,
      {int? rating, String? comment}) async {
    await _dio.put('/reviews/products/$reviewId', data: {
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
    });
  }

  Future<void> deleteProductReview(int reviewId) async {
    await _dio.delete('/reviews/products/$reviewId');
  }

  Future<void> rateProductReview(int reviewId, bool isHelpful) async {
    await _dio.post('/reviews/products/$reviewId/rate',
        data: {'is_helpful': isHelpful});
  }

  Future<void> rateVendorReview(int reviewId, bool isHelpful) async {
    await _dio.post('/reviews/vendors/$reviewId/rate',
        data: {'is_helpful': isHelpful});
  }

  Future<void> removeReviewRating(int reviewId) async {
    await _dio.delete('/reviews/$reviewId/rating');
  }

  // ============ OFFERS ============
  Future<List<Map<String, dynamic>>> offers(
      {Map<String, dynamic>? filters}) async {
    try {
      final res = await _dio.get('/offers', queryParameters: filters);
      final responseData = res.data as Map<String, dynamic>;

      // معالجة response structure بشكل آمن
      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      print('⚠️ Offers response structure غير متوقع: $responseData');
      return [];
    } catch (e) {
      print('❌ خطأ في offers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> featuredOffers() async {
    try {
      final res = await _dio.get('/offers/featured');
      final responseData = res.data as Map<String, dynamic>;

      // معالجة response structure بشكل آمن
      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      print('⚠️ Featured offers response structure غير متوقع: $responseData');
      return [];
    } catch (e) {
      print('❌ خطأ في featuredOffers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> flashSaleOffers() async {
    try {
      final res = await _dio.get('/offers/flash-sale');
      final responseData = res.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      print('❌ خطأ في flashSaleOffers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchOffers(String q) async {
    try {
      final res = await _dio.get('/offers/search', queryParameters: {'q': q});
      final responseData = res.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      print('❌ خطأ في searchOffers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> offerDetails(int id) async {
    final res = await _dio.get('/offers/$id');
    final responseData = res.data as Map<String, dynamic>;

    if (responseData['data'] != null) {
      return responseData['data'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<List<Map<String, dynamic>>> offersByCategory(int categoryId) async {
    try {
      final res = await _dio.get('/offers/category/$categoryId');
      final responseData = res.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      print('❌ خطأ في offersByCategory: $e');
      return [];
    }
  }

  // ============ OFFER CATEGORIES ============
  Future<List<Map<String, dynamic>>> offerCategories() async {
    try {
      final res = await _dio.get('/offer-categories');
      final responseData = res.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      print('⚠️ Offer categories response structure غير متوقع: $responseData');
      return [];
    } catch (e) {
      print('❌ خطأ في offerCategories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> offerCategoryDetails(int id) async {
    final res = await _dio.get('/offer-categories/$id');
    final responseData = res.data as Map<String, dynamic>;

    if (responseData['data'] != null) {
      return responseData['data'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<List<Map<String, dynamic>>> offerCategoryOffers(int categoryId) async {
    try {
      final res = await _dio.get('/offer-categories/$categoryId/offers');
      final responseData = res.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        if (responseData['data'] is List) {
          return (responseData['data'] as List).cast<Map<String, dynamic>>();
        } else if (responseData['data'] is Map &&
            responseData['data']['data'] is List) {
          return (responseData['data']['data'] as List)
              .cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      print('❌ خطأ في offerCategoryOffers: $e');
      return [];
    }
  }

  // ============ CART ============
  Future<Map<String, dynamic>> cart() async {
    final res = await _dio.get('/cart');
    return res.data as Map<String, dynamic>;
  }

  Future<int> cartCount() async {
    final res = await _dio.get('/cart/count');
    return res.data['count'] as int;
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      final res = await _dio.post('/cart', data: {
        'product_id': productId,
        'quantity': quantity,
      });

      // التحقق من استجابة الخطأ (مثل عدم توفر المخزون)
      if (res.data is Map && res.data['success'] == false) {
        final message = res.data['message'] ?? 'فشل إضافة المنتج للسلة';
        print('❌ [API] addToCart فشل: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      // معالجة خطأ 422 (Validation Error) أو أخطاء أخرى
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        final message = data['message'] ?? 'فشل إضافة المنتج للسلة';
        print('❌ [API] addToCart خطأ ${e.response!.statusCode}: $message');
        throw Exception(message);
      }
      // إعادة إلقاء الخطأ إذا لم يكن هناك رسالة
      rethrow;
    }
  }

  /// إضافة عرض للسلة باستخدام offer_id
  Future<void> addOfferToCart(int offerId, {int quantity = 1}) async {
    try {
      // استخدام نفس endpoint /cart مع type: 'offer'
      final res = await _dio.post('/cart', data: {
        'product_id': offerId,
        'quantity': quantity,
        'type': 'offer',
      });

      // التحقق من استجابة الخطأ
      if (res.data is Map && res.data['success'] == false) {
        final message = res.data['message'] ?? 'فشل إضافة العرض للسلة';
        print('❌ [API] addOfferToCart فشل: $message');
        throw Exception(message);
      }

      print('✅ تم إضافة العرض #$offerId للسلة');
    } on DioException catch (e) {
      // معالجة خطأ 422 (Validation Error) أو أخطاء أخرى
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        final message = data['message'] ?? 'فشل إضافة العرض للسلة';
        print('❌ [API] addOfferToCart خطأ ${e.response!.statusCode}: $message');
        throw Exception(message);
      }
      rethrow;
    } catch (e) {
      print('❌ خطأ في addOfferToCart: $e');
      rethrow;
    }
  }

  Future<void> updateCart(int productId, int quantity) async {
    await _dio.put('/cart/$productId', data: {'quantity': quantity});
  }

  Future<void> removeFromCart(int productId) async {
    await _dio.delete('/cart/$productId');
  }

  Future<void> clearCart() async {
    await _dio.delete('/cart');
  }

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    final res = await _dio.post('/cart/coupon/apply', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<void> removeCoupon() async {
    await _dio.delete('/cart/coupon/remove');
  }

  // ============ CHECKOUT ============
  Future<Map<String, dynamic>> getCheckoutData() async {
    final res = await _dio.get('/checkout/data');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkout({
    required String name,
    required String email,
    required String phone,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryGovernorate,
    String? deliveryNotes,
    String deliveryType = 'immediate',
    String paymentMethod = 'cash',
  }) async {
    final res = await _dio.post('/checkout', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'delivery_address': deliveryAddress,
      'delivery_city': deliveryCity,
      'delivery_governorate': deliveryGovernorate,
      'delivery_notes': deliveryNotes,
      'delivery_type': deliveryType,
      'payment_method': paymentMethod,
    });
    return res.data as Map<String, dynamic>;
  }

  // ============ MYFATOORAH PAYMENT ============

  /// تنفيذ الدفع عبر MyFatoorah - إنشاء فاتورة والحصول على رابط الدفع
  Future<Map<String, dynamic>> executeMyFatoorahPayment({
    required int orderId,
    double? amount,
    String? currency,
    int? paymentMethodId,
    Map<String, dynamic>? customer,
  }) async {
    final res = await _dio.post('/payments/myfatoorah/execute', data: {
      'order_id': orderId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (customer != null) 'customer': customer,
    });
    return res.data as Map<String, dynamic>;
  }

  /// الاستعلام عن حالة معاملة الدفع
  Future<Map<String, dynamic>> getMyFatoorahPaymentStatus(
      int transactionId) async {
    final res = await _dio.get('/payments/myfatoorah/status', queryParameters: {
      'transaction_id': transactionId,
    });
    return res.data as Map<String, dynamic>;
  }

  /// جلب طرق الدفع المتاحة
  Future<List<Map<String, dynamic>>> getAvailablePaymentMethods() async {
    try {
      final res = await _dio.get('/payment-methods');
      final List data = res.data['data'] as List? ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching payment methods: $e');
      // إرجاع طريقة الدفع النقدي كافتراضية
      return [
        {'code': 'cash', 'name': 'الدفع عند الاستلام', 'is_active': true}
      ];
    }
  }

  /// التحقق من توفر بوابة MyFatoorah
  Future<bool> isMyFatoorahEnabled() async {
    try {
      final methods = await getAvailablePaymentMethods();
      return methods
          .any((m) => m['code'] == 'myfatoorah' && m['is_active'] == true);
    } catch (e) {
      return false;
    }
  }

  // ============ WISHLIST ============
  Future<Map<String, dynamic>> wishlist() async {
    final res = await _dio.get('/wishlist');
    return res.data as Map<String, dynamic>;
  }

  Future<void> addWishlist(int productId) async {
    await _dio.post('/wishlist', data: {'product_id': productId});
  }

  Future<void> removeWishlist(int productId) async {
    await _dio.delete('/wishlist/$productId');
  }

  // ============ ORDERS ============
  Future<List<dynamic>> recentOrders() async {
    final res = await _dio.get('/orders/recent');
    return (res.data['orders'] as List?) ?? <dynamic>[];
  }

  Future<Map<String, dynamic>> trackOrder(String orderNumber) async {
    final res = await _dio.get('/orders/track/$orderNumber');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> orderConfirmation(String orderNumber) async {
    final res = await _dio.get('/orders/confirmation/$orderNumber');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> orderDetails(int orderId) async {
    final res = await _dio.get('/orders/$orderId/details');
    return res.data as Map<String, dynamic>;
  }

  Future<void> downloadInvoice(String orderNumber) async {
    await _dio.get('/orders/invoice/$orderNumber');
  }

  // ============ AUTH ============
  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio
        .post('/auth/login', data: {'email': email, 'password': password});

    // معالجة response structure من API
    final responseData = res.data as Map<String, dynamic>;

    // التحقق من وجود data أو token مباشرة
    if (responseData['data'] != null) {
      return responseData['data'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {String? phone}) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginCustomer(
      {required String email, required String password}) async {
    return await login(email, password);
  }

  Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    return await register(name, email, password, phone: phone);
  }

  Future<Map<String, dynamic>> loginVendor(
      {required String email, required String password}) async {
    return await vendorLogin(email, password);
  }

  Future<Map<String, dynamic>> registerVendor({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String storeName,
    String? description,
  }) async {
    // سنحتاج للحصول على governorate, city, business_category من المستخدم
    // لكن الآن سنستخدم قيم افتراضية
    await vendorRegister(
      storeName: storeName,
      email: email,
      password: password,
      phone: phone,
      governorateId: 1, // قيمة افتراضية
      cityId: 1, // قيمة افتراضية
      businessCategoryId: 1, // قيمة افتراضية
      description: description,
    );

    // بعد التسجيل، نقوم بتسجيل الدخول
    return await vendorLogin(email, password);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<void> deleteAccount({required String password}) async {
    await _dio.delete('/auth/account', data: {
      'password': password,
      'confirmation': true,
    });
  }

  Future<void> deleteVendorAccount({required String password}) async {
    await _dio.delete('/vendor/auth/account', data: {
      'password': password,
      'confirmation': true,
    });
  }

  Future<void> updateProfile(
      {String? name, String? email, String? phone, String? birthDate}) async {
    await _dio.put('/auth/profile', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (birthDate != null) 'birth_date': birthDate,
    });
  }

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    await _dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // ============ VENDOR AUTH ============
  Future<void> vendorRegister({
    required String storeName,
    required String email,
    required String password,
    required String phone,
    required int governorateId,
    required int cityId,
    required int businessCategoryId,
    String? description,
    List<int>? contactMethodIds,
  }) async {
    await _dio.post('/vendor/auth/register', data: {
      'store_name': storeName,
      'email': email,
      'password': password,
      'phone': phone,
      'governorate_id': governorateId,
      'city_id': cityId,
      'business_category_id': businessCategoryId,
      if (description != null) 'description': description,
      if (contactMethodIds != null) 'contact_method_ids': contactMethodIds,
    });
  }

  Future<Map<String, dynamic>> vendorLogin(
      String email, String password) async {
    final res = await _dio.post('/vendor/auth/login', data: {
      'email': email,
      'password': password,
    });

    // معالجة response structure من API
    final responseData = res.data as Map<String, dynamic>;

    // التحقق من وجود data
    if (responseData['data'] != null) {
      final data = responseData['data'] as Map<String, dynamic>;
      // تحويل vendor إلى user لتتوافق مع AuthProvider
      return {
        'token': data['token'],
        'user': data['vendor'],
      };
    }

    // إذا كان الرد بالشكل القديم، نرجعه كما هو
    return responseData;
  }

  Future<void> vendorLogout() async {
    await _dio.post('/vendor/auth/logout');
  }

  Future<Map<String, dynamic>> vendorMe() async {
    final res = await _dio.get('/vendor/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> vendorUpdateProfile(Map<String, dynamic> data) async {
    await _dio.put('/vendor/auth/profile', data: data);
  }

  Future<Map<String, dynamic>> vendorValidateToken(String token) async {
    final res =
        await _dio.post('/vendor/auth/validate-token', data: {'token': token});
    return res.data as Map<String, dynamic>;
  }

  // ============ VENDOR DASHBOARD ============
  Future<Map<String, dynamic>> vendorDashboardStats() async {
    final res = await _dio.get('/vendor/dashboard/stats');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> vendorRecentOrders() async {
    final res = await _dio.get('/vendor/dashboard/recent-orders');
    final List data = res.data['orders'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> vendorTopProducts() async {
    final res = await _dio.get('/vendor/dashboard/top-products');
    final List data = res.data['products'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> vendorNotifications() async {
    final res = await _dio.get('/vendor/dashboard/notifications');
    final List data = res.data['notifications'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> vendorMarkNotificationsRead(List<int> notificationIds) async {
    await _dio.post('/vendor/dashboard/notifications/mark-read', data: {
      'notification_ids': notificationIds,
    });
  }

  Future<int> vendorUnreadNotificationsCount() async {
    final res = await _dio.get('/vendor/dashboard/notifications/unread-count');
    return res.data['count'] as int;
  }

  // ============ VENDOR PRODUCTS ============
  Future<List<Map<String, dynamic>>> vendorGetProducts(
      {Map<String, dynamic>? params}) async {
    final res = await _dio.get('/vendor/products', queryParameters: params);
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> vendorCreateProduct(
    Map<String, dynamic> data, {
    File? imageFile,
  }) async {
    // إذا كانت هناك صورة، نستخدم FormData
    if (imageFile != null) {
      final formData = FormData();

      // إضافة بيانات المنتج
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // إضافة الصورة
      formData.files.add(MapEntry(
        'image',
        await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      ));

      final res = await _dio.post('/vendor/products', data: formData);
      return res.data as Map<String, dynamic>;
    }

    // إذا لم تكن هناك صورة، نستخدم JSON عادي
    final res = await _dio.post('/vendor/products', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorGetProduct(int productId) async {
    final res = await _dio.get('/vendor/products/$productId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorUpdateProduct(
      int productId, Map<String, dynamic> data) async {
    final res = await _dio.put('/vendor/products/$productId', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> vendorDeleteProduct(int productId) async {
    await _dio.delete('/vendor/products/$productId');
  }

  // ============ VENDOR ORDERS ============
  Future<List<Map<String, dynamic>>> vendorGetOrders(
      {Map<String, dynamic>? params}) async {
    final res = await _dio.get('/vendor/orders', queryParameters: params);
    // VendorOrderController returns 'orders' not 'data'
    final List data =
        res.data['orders'] as List? ?? res.data['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> vendorGetOrder(int orderId) async {
    final res = await _dio.get('/vendor/orders/$orderId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorUpdateOrderStatus(
      int orderId, String status) async {
    final res = await _dio
        .put('/vendor/orders/$orderId/status', data: {'status': status});
    return res.data as Map<String, dynamic>;
  }

  // ============ VENDOR REPORTS ============
  Future<Map<String, dynamic>> vendorReports(
      {Map<String, dynamic>? params}) async {
    final res = await _dio.get('/vendor/reports', queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorSalesReport(
      {String? startDate, String? endDate}) async {
    final res = await _dio.get('/vendor/reports/sales', queryParameters: {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorProductsReport() async {
    final res = await _dio.get('/vendor/reports/products');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorRevenueReport(
      {String? startDate, String? endDate}) async {
    final res = await _dio.get('/vendor/reports/revenue', queryParameters: {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return res.data as Map<String, dynamic>;
  }

  // ============ VENDOR SETTINGS ============
  Future<Map<String, dynamic>> vendorGetSettings() async {
    final res = await _dio.get('/vendor/settings');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vendorUpdateSettings(
      Map<String, dynamic> data) async {
    final res = await _dio.put('/vendor/settings', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ============ ADDRESSES ============
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final res = await _dio.get('/addresses');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> data) async {
    final res = await _dio.post('/addresses', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAddress(
      int addressId, Map<String, dynamic> data) async {
    final res = await _dio.put('/addresses/$addressId', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteAddress(int addressId) async {
    await _dio.delete('/addresses/$addressId');
  }

  Future<void> setDefaultAddress(int addressId) async {
    await _dio.post('/addresses/$addressId/default');
  }

  // ============ NOTIFICATION SETTINGS ============
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final res = await _dio.get('/notification-settings');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNotificationSettings(
      Map<String, dynamic> data) async {
    final res = await _dio.put('/notification-settings', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final res = await _dio.get('/notification-preferences');
    return res.data as Map<String, dynamic>;
  }

  // ============ CONTACT ============
  Future<void> sendContact({
    required String name,
    required String email,
    required String subject,
    required String message,
    String? phone,
  }) async {
    await _dio.post('/contact', data: {
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      if (phone != null) 'phone': phone,
    });
  }

  // ============ STATIC PAGES ============
  Future<List<Map<String, dynamic>>> getStaticPages() async {
    try {
      final res = await _dio.get('/static-pages');
      final responseData = res.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        return (responseData['data'] as List).cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('❌ خطأ في getStaticPages: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStaticPage(String slug) async {
    final res = await _dio.get('/static-pages/$slug');
    final responseData = res.data as Map<String, dynamic>;

    if (responseData['data'] != null) {
      return responseData['data'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<Map<String, dynamic>> getTermsPage() async {
    final res = await _dio.get('/terms');
    final responseData = res.data as Map<String, dynamic>;

    if (responseData['data'] != null) {
      return responseData['data'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<Map<String, dynamic>> getPrivacyPage() async {
    final res = await _dio.get('/privacy');
    final responseData = res.data as Map<String, dynamic>;

    if (responseData['data'] != null) {
      return responseData['data'] as Map<String, dynamic>;
    }

    return responseData;
  }

  Future<Map<String, dynamic>> getContactStats() async {
    final res = await _dio.get('/contact/stats');
    return res.data as Map<String, dynamic>;
  }

  // ============ FAQ ============
  Future<List<Map<String, dynamic>>> getFaqs() async {
    final res = await _dio.get('/faqs');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFaqCategories() async {
    final res = await _dio.get('/faqs/categories');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getFaqDetails(int faqId) async {
    final res = await _dio.get('/faqs/$faqId');
    return res.data as Map<String, dynamic>;
  }

  // ============ COUPONS ============
  Future<List<Map<String, dynamic>>> getCoupons() async {
    final res = await _dio.get('/coupons');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> validateCoupon(String code) async {
    final res = await _dio.post('/coupons/validate', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyCouponCode(String code) async {
    final res = await _dio.post('/coupons/apply', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  // ============ NEWSLETTER ============
  Future<void> subscribeNewsletter(String email) async {
    await _dio.post('/newsletter/subscribe', data: {'email': email});
  }

  Future<void> unsubscribeNewsletter(String email) async {
    await _dio.post('/newsletter/unsubscribe', data: {'email': email});
  }

  Future<void> resubscribeNewsletter(String email) async {
    await _dio.post('/newsletter/resubscribe', data: {'email': email});
  }

  Future<Map<String, dynamic>> checkNewsletterSubscription(String email) async {
    final res =
        await _dio.get('/newsletter/check', queryParameters: {'email': email});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNewsletterStats() async {
    final res = await _dio.get('/newsletter/stats');
    return res.data as Map<String, dynamic>;
  }

  // ============ SETTINGS ============
  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get('/settings');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGeneralSettings() async {
    final res = await _dio.get('/settings/general');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEmailSettings() async {
    final res = await _dio.get('/settings/email');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPaymentSettings() async {
    final res = await _dio.get('/settings/payment');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSeoSettings() async {
    final res = await _dio.get('/settings/seo');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDesignSettings() async {
    final res = await _dio.get('/settings/design');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDeveloperSettings() async {
    final res = await _dio.get('/settings/developer');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSettingsByGroup(String group) async {
    final res = await _dio.get('/settings/$group');
    return res.data as Map<String, dynamic>;
  }

  Future<dynamic> getSettingByKey(String key) async {
    final res = await _dio.get('/settings/key/$key');
    return res.data['value'];
  }

  // ============ SUPPORT CHANNELS ============
  Future<List<Map<String, dynamic>>> getSupportChannels() async {
    final res = await _dio.get('/support-channels');
    final List data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getSupportChannelDetails(int channelId) async {
    final res = await _dio.get('/support-channels/$channelId');
    return res.data as Map<String, dynamic>;
  }

  // ============ ABOUT PAGE ============
  Future<Map<String, dynamic>> getAboutPage() async {
    final res = await _dio.get('/about');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutSection(String section) async {
    final res = await _dio.get('/about/section/$section');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutHero() async {
    final res = await _dio.get('/about/hero');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutStory() async {
    final res = await _dio.get('/about/story');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutValues() async {
    final res = await _dio.get('/about/values');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutStatistics() async {
    final res = await _dio.get('/about/statistics');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutTeam() async {
    final res = await _dio.get('/about/team');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAboutMission() async {
    final res = await _dio.get('/about/mission');
    return res.data as Map<String, dynamic>;
  }

  // ============ SLIDERS ============
  Future<List<SliderModel>> getSliders() async {
    try {
      print('📡 جلب السلايدرات من: ${ApiConfig.baseUrl}/sliders');
      final res = await _dio.get('/sliders');

      // معالجة structures مختلفة من الـ API
      List data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else if (res.data is Map && res.data['sliders'] is List) {
        data = res.data['sliders'] as List;
      } else {
        print('⚠️ Sliders response structure غير متوقع: ${res.data}');
        return [];
      }

      print('✅ تم استلام ${data.length} سلايدرات من API');

      // تحويل إلى SliderModel
      final sliders = data
          .map((slider) => SliderModel.fromApi(slider as Map<String, dynamic>))
          .where((slider) => slider.isActive)
          .toList();

      print('📊 السلايدرات النشطة: ${sliders.length}');
      if (sliders.isNotEmpty) {
        print('🖼️  أول سلايدر: ${sliders[0].title}');
        print('📸 صورة أول سلايدر: ${sliders[0].image}');
      }

      return sliders;
    } catch (e, stackTrace) {
      print('❌ خطأ في getSliders: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSliderDetails(int sliderId) async {
    final res = await _dio.get('/sliders/$sliderId');
    return res.data as Map<String, dynamic>;
  }

  // ============ DEMO ============
  Future<Map<String, dynamic>> demoSeed() async {
    final res = await _dio.post('/demo/seed');
    return res.data as Map<String, dynamic>;
  }
}
