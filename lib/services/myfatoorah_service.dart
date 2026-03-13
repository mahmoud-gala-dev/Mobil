import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// MyFatoorah Payment Service
/// خدمة الدفع عبر MyFatoorah - تتواصل مع Laravel API
class MyFatoorahService {
  MyFatoorahService._();
  static final MyFatoorahService instance = MyFatoorahService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    headers: ApiConfig.defaultHeaders,
  ));

  // ─────────────────────────────────────────────────────────────────────────
  // Execute Payment - إنشاء فاتورة والحصول على رابط الدفع
  // ─────────────────────────────────────────────────────────────────────────

  /// تنفيذ عملية الدفع وإرجاع رابط صفحة الدفع
  /// [orderId] معرف الطلب
  /// [amount] المبلغ (اختياري - يؤخذ من الطلب افتراضياً)
  /// [currency] العملة (اختياري - افتراضي KWD)
  /// [customer] بيانات العميل
  Future<ExecutePaymentResult> executePayment({
    required int orderId,
    double? amount,
    String? currency,
    int? paymentMethodId,
    CustomerInfo? customer,
    String? authToken,
  }) async {
    final requestId = 'exec_${DateTime.now().millisecondsSinceEpoch}';

    _log('Execute Payment - START', {
      'requestId': requestId,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
    });

    try {
      final payload = <String, dynamic>{
        'order_id': orderId,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
        if (customer != null) 'customer': customer.toJson(),
      };

      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _dio.post(
        '/payments/myfatoorah/execute',
        data: payload,
        options: Options(headers: headers),
      );

      final data = response.data;

      if (data['ok'] == true) {
        _log('Execute Payment - SUCCESS', {
          'requestId': requestId,
          'transactionId': data['transaction_id'],
          'invoiceId': data['invoice_id'],
        });

        return ExecutePaymentResult(
          success: true,
          paymentUrl: data['payment_url'],
          invoiceId: data['invoice_id']?.toString(),
          transactionId: data['transaction_id'],
        );
      } else {
        _logError('Execute Payment - API ERROR', {
          'requestId': requestId,
          'code': data['code'],
          'message': data['message'],
          'errorType': data['error_type'],
        });

        return ExecutePaymentResult(
          success: false,
          errorMessage: data['message'] ?? 'فشل في إنشاء عملية الدفع',
          errorCode: data['code'],
          errorType: data['error_type'],
        );
      }
    } on DioException catch (e) {
      _logError('Execute Payment - NETWORK ERROR', {
        'requestId': requestId,
        'error': e.message,
        'type': e.type.toString(),
      });

      String message = 'تعذّر الاتصال بخادم الدفع';
      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'انتهت مهلة الاتصال بالخادم';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'انتهت مهلة استقبال البيانات';
      }

      return ExecutePaymentResult(
        success: false,
        errorMessage: message,
        errorCode: 'NETWORK_ERROR',
        errorType: 'NETWORK_ERROR',
      );
    } catch (e) {
      _logError('Execute Payment - EXCEPTION', {
        'requestId': requestId,
        'error': e.toString(),
      });

      return ExecutePaymentResult(
        success: false,
        errorMessage: 'حدث خطأ غير متوقع',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get Payment Status - استعلام عن حالة الدفع
  // ─────────────────────────────────────────────────────────────────────────

  /// الاستعلام عن حالة معاملة الدفع
  Future<PaymentStatusResult> getPaymentStatus({
    required int transactionId,
    String? authToken,
  }) async {
    final requestId = 'status_${transactionId}_${DateTime.now().millisecondsSinceEpoch}';

    _log('Get Payment Status - START', {
      'requestId': requestId,
      'transactionId': transactionId,
    });

    try {
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _dio.get(
        '/payments/myfatoorah/status',
        queryParameters: {'transaction_id': transactionId},
        options: Options(headers: headers),
      );

      final data = response.data;

      if (data['ok'] == true) {
        _log('Get Payment Status - SUCCESS', {
          'requestId': requestId,
          'status': data['status'],
          'orderId': data['order_id'],
        });

        return PaymentStatusResult(
          success: true,
          status: PaymentStatus.fromString(data['status'] ?? 'pending'),
          orderId: data['order_id'],
          invoiceId: data['invoice_id']?.toString(),
          paidAt: data['paid_at'] != null ? DateTime.tryParse(data['paid_at']) : null,
        );
      } else {
        _logError('Get Payment Status - ERROR', {
          'requestId': requestId,
          'message': data['message'],
        });

        return PaymentStatusResult(
          success: false,
          errorMessage: data['message'] ?? 'فشل في جلب حالة الدفع',
        );
      }
    } on DioException catch (e) {
      _logError('Get Payment Status - NETWORK ERROR', {
        'requestId': requestId,
        'error': e.message,
      });

      return PaymentStatusResult(
        success: false,
        errorMessage: 'تعذّر الاتصال بالخادم',
      );
    } catch (e) {
      _logError('Get Payment Status - EXCEPTION', {
        'requestId': requestId,
        'error': e.toString(),
      });

      return PaymentStatusResult(
        success: false,
        errorMessage: 'حدث خطأ غير متوقع',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Check Gateway Availability - التحقق من توفر البوابة
  // ─────────────────────────────────────────────────────────────────────────

  /// التحقق من تفعيل بوابة MyFatoorah
  Future<bool> isGatewayEnabled({String? authToken}) async {
    try {
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _dio.get(
        '/payment-methods',
        options: Options(headers: headers),
      );

      final methods = response.data['data'] as List?;
      if (methods != null) {
        return methods.any((m) => m['code'] == 'myfatoorah' && m['is_active'] == true);
      }
      return false;
    } catch (e) {
      _logError('Check Gateway - ERROR', {'error': e.toString()});
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _log(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      print('[MyFatoorah] $message ${data ?? ''}');
    }
  }

  void _logError(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      print('[MyFatoorah] ERROR: $message ${data ?? ''}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

/// معلومات العميل للدفع
class CustomerInfo {
  final String? name;
  final String? email;
  final String? mobile;
  final String? mobileCountryCode;

  CustomerInfo({
    this.name,
    this.email,
    this.mobile,
    this.mobileCountryCode,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (mobile != null) 'mobile': mobile,
    if (mobileCountryCode != null) 'mobile_country_code': mobileCountryCode,
  };
}

/// نتيجة تنفيذ الدفع
class ExecutePaymentResult {
  final bool success;
  final String? paymentUrl;
  final String? invoiceId;
  final int? transactionId;
  final String? errorMessage;
  final String? errorCode;
  final String? errorType;

  ExecutePaymentResult({
    required this.success,
    this.paymentUrl,
    this.invoiceId,
    this.transactionId,
    this.errorMessage,
    this.errorCode,
    this.errorType,
  });

  /// هل الخطأ يتطلب إجراء من المسؤول؟
  bool get isAdminActionRequired =>
    errorType == 'TOKEN_INVALID' || errorType == 'SSL_ERROR';

  /// رسالة مناسبة للعرض للمستخدم
  String get displayMessage {
    if (success) return 'تم إنشاء عملية الدفع بنجاح';

    switch (errorType) {
      case 'TOKEN_INVALID':
        return 'بوابة الدفع غير متاحة حالياً. يرجى التواصل مع الدعم الفني.';
      case 'SSL_ERROR':
        return 'مشكلة في الاتصال الآمن. يرجى المحاولة لاحقاً.';
      case 'NETWORK_ERROR':
        return 'تعذّر الاتصال ببوابة الدفع. تحقق من اتصالك بالإنترنت.';
      default:
        return errorMessage ?? 'حدث خطأ أثناء عملية الدفع';
    }
  }
}

/// نتيجة استعلام حالة الدفع
class PaymentStatusResult {
  final bool success;
  final PaymentStatus? status;
  final int? orderId;
  final String? invoiceId;
  final DateTime? paidAt;
  final String? errorMessage;

  PaymentStatusResult({
    required this.success,
    this.status,
    this.orderId,
    this.invoiceId,
    this.paidAt,
    this.errorMessage,
  });

  /// هل تم الدفع بنجاح؟
  bool get isPaid => status == PaymentStatus.paid;

  /// هل الدفع قيد المعالجة؟
  bool get isInProgress => status == PaymentStatus.inProgress;

  /// هل فشل الدفع؟
  bool get isFailed => status == PaymentStatus.failed || status == PaymentStatus.canceled;
}

/// حالات الدفع
enum PaymentStatus {
  pending,
  inProgress,
  paid,
  failed,
  canceled;

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'inprogress':
      case 'in_progress':
        return PaymentStatus.inProgress;
      case 'failed':
        return PaymentStatus.failed;
      case 'canceled':
      case 'cancelled':
        return PaymentStatus.canceled;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'قيد الانتظار';
      case PaymentStatus.inProgress:
        return 'قيد المعالجة';
      case PaymentStatus.paid:
        return 'مدفوع';
      case PaymentStatus.failed:
        return 'فشل';
      case PaymentStatus.canceled:
        return 'ملغي';
    }
  }

  String get arabicStatus {
    switch (this) {
      case PaymentStatus.pending:
        return 'في انتظار الدفع';
      case PaymentStatus.inProgress:
        return 'جاري معالجة الدفع';
      case PaymentStatus.paid:
        return 'تم الدفع بنجاح';
      case PaymentStatus.failed:
        return 'فشلت عملية الدفع';
      case PaymentStatus.canceled:
        return 'تم إلغاء عملية الدفع';
    }
  }
}
