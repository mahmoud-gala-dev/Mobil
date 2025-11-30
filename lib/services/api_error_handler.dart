import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// معالج أخطاء API مركزي
class ApiErrorHandler {
  /// معالجة أخطاء Dio وتحويلها إلى رسائل مفهومة
  static String handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    
    return 'حدث خطأ غير متوقع: ${error.toString()}';
  }

  /// معالجة أخطاء Dio محددة
  static String _handleDioError(DioException error) {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ API Error Details:');
      print('Type: ${error.type}');
      print('Message: ${error.message}');
      print('URL: ${error.requestOptions.uri}');
      print('Method: ${error.requestOptions.method}');
      if (error.response != null) {
        print('Status Code: ${error.response?.statusCode}');
        print('Response Data: ${error.response?.data}');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '''
🔌 انتهت مهلة الاتصال

السبب: لم يستجب الخادم خلال ${_formatDuration(error.requestOptions.connectTimeout!)}

الحلول المقترحة:
✅ تأكد من تشغيل الخادم API
✅ تحقق من عنوان API: ${error.requestOptions.baseUrl}
✅ تحقق من اتصال الإنترنت
✅ للمحاكي Android، استخدم 10.0.2.2 بدلاً من localhost
✅ للجهاز الفعلي، استخدم IP الفعلي للكمبيوتر

💡 نصيحة: راجع دليل استكشاف الأخطاء في API_CONNECTION_TROUBLESHOOTING.md
''';

      case DioExceptionType.sendTimeout:
        return '''
⏱️ انتهت مهلة إرسال البيانات

السبب: استغرق إرسال البيانات وقتاً طويلاً

الحلول:
✅ تحقق من سرعة الإنترنت
✅ قلل حجم البيانات المرسلة
✅ حاول مرة أخرى
''';

      case DioExceptionType.receiveTimeout:
        return '''
📥 انتهت مهلة استقبال البيانات

السبب: الخادم لم يرسل البيانات في الوقت المحدد

الحلول:
✅ تحقق من سرعة الإنترنت
✅ حاول مرة أخرى
✅ قد يكون الخادم مشغولاً
''';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';

      case DioExceptionType.connectionError:
        return '''
🚫 فشل الاتصال بالخادم

السبب: ${error.message ?? 'غير معروف'}

الحلول المقترحة:
✅ تأكد من تشغيل الخادم API على: ${error.requestOptions.baseUrl}
✅ للمحاكي Android: استخدم http://10.0.2.2:8000/api/v1
✅ للجهاز الفعلي: استخدم http://[YOUR_IP]:8000/api/v1
✅ تحقق من Firewall وأنه لا يحجب المنفذ
✅ تأكد من صلاحيات الإنترنت في AndroidManifest.xml

📝 أوامر مفيدة:
   Windows: ipconfig
   Mac/Linux: ifconfig
   Test: curl ${error.requestOptions.baseUrl}/ping

💡 للتطوير بدون خادم، فعّل Mock API في api_config.dart
''';

      case DioExceptionType.badCertificate:
        return '''
🔒 خطأ في شهادة SSL

الحلول:
✅ تحقق من صحة شهادة SSL
✅ للتطوير، استخدم http بدلاً من https
''';

      case DioExceptionType.unknown:
        return '''
❌ خطأ غير معروف

التفاصيل: ${error.message ?? 'لا توجد تفاصيل'}

الحلول:
✅ تحقق من اتصال الإنترنت
✅ أعد تشغيل التطبيق
✅ اتصل بالدعم الفني
''';
    }
  }

  /// معالجة أخطاء الاستجابة السيئة (4xx, 5xx)
  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final data = error.response?.data;

    // محاولة استخراج رسالة الخطأ من الاستجابة
    String? serverMessage;
    if (data is Map) {
      serverMessage = data['message'] ?? data['error'] ?? data['msg'];
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'طلب غير صحيح';
      
      case 401:
        return 'جلسة العمل انتهت. يرجى تسجيل الدخول مرة أخرى';
      
      case 403:
        return 'ليس لديك صلاحية للوصول إلى هذا المحتوى';
      
      case 404:
        return 'المحتوى المطلوب غير موجود';
      
      case 422:
        if (data is Map && data['errors'] != null) {
          // Laravel validation errors
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
        return serverMessage ?? 'بيانات غير صحيحة';
      
      case 429:
        return 'تم تجاوز عدد المحاولات المسموح بها. يرجى المحاولة لاحقاً';
      
      case 500:
        return 'خطأ في الخادم. يرجى المحاولة لاحقاً';
      
      case 502:
        return 'الخادم غير متاح مؤقتاً';
      
      case 503:
        return 'الخادم في وضع الصيانة';
      
      default:
        return serverMessage ?? 'حدث خطأ (الكود: $statusCode)';
    }
  }

  /// تنسيق Duration بشكل مقروء
  static String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} دقيقة';
    } else {
      return '${duration.inSeconds} ثانية';
    }
  }

  /// التحقق من إمكانية إعادة المحاولة
  static bool canRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError ||
           (error.type == DioExceptionType.badResponse && 
            error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  /// الحصول على رسالة قصيرة للـ UI
  static String getShortMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.connectionError:
          return 'فشل الاتصال بالخادم';
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'انتهت مهلة الطلب';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          if (statusCode == 401) return 'يرجى تسجيل الدخول';
          if (statusCode == 404) return 'المحتوى غير موجود';
          if (statusCode >= 500) return 'خطأ في الخادم';
          return 'حدث خطأ';
        default:
          return 'حدث خطأ';
      }
    }
    return 'حدث خطأ غير متوقع';
  }
}

