import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'shared_preferences_service.dart';

/// Auth Interceptor
/// 
/// يضيف Bearer Token تلقائياً إلى جميع الطلبات ويعالج أخطاء المصادقة
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // التأكد من جاهزية SharedPreferences قبل محاولة القراءة
    if (!SharedPreferencesService.instance.isReady) {
      // محاولة إعادة التهيئة إذا لم تكن جاهزة
      if (kDebugMode) {
        print('🔄 [AuthInterceptor] SharedPreferences غير جاهزة، محاولة إعادة التهيئة...');
      }
      
      final initialized = await SharedPreferencesService.instance.init();
      if (!initialized) {
        if (kDebugMode) {
          print('⚠️ [AuthInterceptor] فشل تهيئة SharedPreferences - سيتم إرسال الطلب بدون Token');
        }
        handler.next(options);
        return;
      }
    }

    // جلب Token من SharedPreferences بشكل آمن
    final token = SharedPreferencesService.instance.getString('auth_token');

    // إضافة Token إلى Headers إذا كان موجوداً
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      
      // تسجيل معلومات الطلب للتشخيص
      if (kDebugMode) {
        print('🔐 [AuthInterceptor] إضافة Token للطلب: ${options.path}');
      }
      
      // التحقق من صلاحية Token (اختياري)
      if (_isTokenExpired(token)) {
        if (kDebugMode) {
          print('⚠️ [AuthInterceptor] تحذير: Token قد يكون منتهي الصلاحية');
        }
      }
    } else {
      // عدم تسجيل تحذير للطلبات العامة التي لا تحتاج Token
      // مثل /sliders, /categories, /products/featured (إذا كانت عامة)
      final publicPaths = ['/sliders', '/categories', '/products/featured', '/products'];
      final isPublicPath = publicPaths.any((path) => options.path.contains(path));
      
      if (!isPublicPath && kDebugMode) {
        print('⚠️ [AuthInterceptor] لا يوجد Token محفوظ للطلب: ${options.path}');
      }
    }

    // متابعة الطلب
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // معالجة خاصة لأخطاء المصادقة
    if (err.response?.statusCode == 401) {
      if (kDebugMode) {
        print('❌ [AuthInterceptor] خطأ 401: غير مصرح');
        print('📍 [AuthInterceptor] المسار: ${err.requestOptions.path}');
      }
      
      final responseData = err.response?.data;
      if (responseData is Map) {
        final message = responseData['message'] ?? 'غير مصرح لك بالوصول';
        if (kDebugMode) {
          print('💬 [AuthInterceptor] الرسالة: $message');
        }
        
        // التحقق من أنواع أخطاء 401 المختلفة
        if (message.toString().contains('Token has expired') ||
            message.toString().contains('Invalid authentication token')) {
          if (kDebugMode) {
            print('🔄 [AuthInterceptor] Token منتهي الصلاحية - يجب تسجيل الدخول مرة أخرى');
          }
          _clearAuthData();
        }
      }
      
      // تحويل الخطأ إلى رسالة أوضح
      final enhancedError = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى',
      );
      
      handler.reject(enhancedError);
      return;
    }
    
    // معالجة خطأ 403 (Forbidden)
    if (err.response?.statusCode == 403) {
      if (kDebugMode) {
        print('❌ [AuthInterceptor] خطأ 403: ممنوع');
      }
      final responseData = err.response?.data;
      if (responseData is Map) {
        final message = responseData['message'] ?? 'ليس لديك صلاحية للوصول';
        if (kDebugMode) {
          print('💬 [AuthInterceptor] الرسالة: $message');
        }
      }
    }

    // إرسال الخطأ للمعالج التالي
    handler.next(err);
  }
  
  /// التحقق من انتهاء صلاحية Token
  bool _isTokenExpired(String token) {
    try {
      // فك تشفير Token للتحقق من timestamp
      final parts = token.split('.');
      if (parts.length != 2) return false;
      
      // محاولة فك تشفير الجزء الأول (payload)
      // ملاحظة: هذا يعتمد على تنسيق token المستخدم في backend
      // Token format: base64(payload).hash
      // Payload format: {"vendor_id": X, "timestamp": Y}
      
      // لتبسيط الأمور، سنفترض أن Token صالح لمدة 24 ساعة
      // يمكن تحسين هذا لاحقاً
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthInterceptor] فشل التحقق من صلاحية Token: $e');
      }
      return false;
    }
  }
  
  /// تنظيف بيانات المصادقة
  Future<void> _clearAuthData() async {
    try {
      await SharedPreferencesService.instance.remove('auth_token');
      await SharedPreferencesService.instance.remove('user_data');
      if (kDebugMode) {
        print('🧹 [AuthInterceptor] تم تنظيف بيانات المصادقة');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthInterceptor] فشل تنظيف بيانات المصادقة: $e');
      }
    }
  }
}

