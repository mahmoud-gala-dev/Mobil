import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_error_handler.dart';

/// Interceptor لإعادة محاولة الطلبات الفاشلة تلقائياً
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = ApiConfig.maxRetries,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      print('🔄 RetryInterceptor: Error detected');
      print('   Type: ${err.type}');
      print('   URL: ${err.requestOptions.uri}');
    }

    // التحقق من إمكانية إعادة المحاولة
    if (!ApiErrorHandler.canRetry(err)) {
      if (kDebugMode) {
        print('❌ Cannot retry this error type');
      }
      return handler.next(err);
    }

    // الحصول على عدد المحاولات الحالية
    final retries = err.requestOptions.extra['retries'] ?? 0;

    if (retries >= maxRetries) {
      if (kDebugMode) {
        print('❌ Max retries ($maxRetries) reached');
      }
      return handler.next(err);
    }

    if (kDebugMode) {
      print('🔄 Retrying... Attempt ${retries + 1}/$maxRetries');
    }

    // تحديث عدد المحاولات
    err.requestOptions.extra['retries'] = retries + 1;

    // انتظار قبل إعادة المحاولة (exponential backoff)
    final delay = _calculateDelay(retries);
    if (kDebugMode) {
      print('⏱️ Waiting ${delay.inMilliseconds}ms before retry...');
    }
    await Future.delayed(delay);

    try {
      // إعادة محاولة الطلب
      if (kDebugMode) {
        print('📤 Sending retry request...');
      }

      final response = await dio.request(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
        ),
      );

      if (kDebugMode) {
        print('✅ Retry successful!');
      }

      return handler.resolve(response);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Retry failed: ${e.type}');
      }
      // إذا فشلت المحاولة، سيتم استدعاء onError مرة أخرى
      return handler.next(e);
    }
  }

  /// حساب وقت الانتظار قبل إعادة المحاولة (Exponential Backoff)
  Duration _calculateDelay(int retryCount) {
    // 1s, 2s, 4s, 8s, ...
    final seconds = (1 << retryCount).clamp(1, 10); // Max 10 seconds
    return Duration(seconds: seconds);
  }
}



