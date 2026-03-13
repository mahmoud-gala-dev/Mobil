import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../services/api_service.dart';
import '../domain/entities/payment_method.dart';
import '../domain/payment_config.dart';
import '../domain/payment_state.dart';

/// مزود حالة الدفع - يدير طرق الدفع وعمليات الدفع
class PaymentProvider extends ChangeNotifier {
  PaymentMethodsState _methodsState = const PaymentMethodsState.initial();
  PaymentProcessState _processState = const PaymentProcessState.initial();
  String _selectedMethod = 'cash';

  // Getters
  PaymentMethodsState get methodsState => _methodsState;
  PaymentProcessState get processState => _processState;
  String get selectedMethod => _selectedMethod;
  bool get isMyFatoorahEnabled => _methodsState.isMyFatoorahEnabled;
  bool get isLoading => _methodsState.isLoading;
  bool get isProcessing => _processState.isProcessing;
  List<PaymentMethod> get availableMethods => _methodsState.methods;

  /// تفعيل الوضع التجريبي لـ MyFatoorah (للتطوير)
  /// اضبط على true لإظهار MyFatoorah حتى لو لم يكن مفعّلاً في الخادم
  static const bool _forceEnableMyFatoorahInTestMode = true;

  /// تحميل طرق الدفع المتاحة
  Future<void> loadPaymentMethods() async {
    _methodsState = const PaymentMethodsState.loading();
    notifyListeners();

    try {
      // التحقق من الاتصال بالإنترنت (اختياري)
      try {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
          _methodsState = const PaymentMethodsState.offline();
          notifyListeners();
          return;
        }
      } catch (e) {
        _log('تجاوز فحص الاتصال: $e');
      }

      // جلب طرق الدفع من API
      List<Map<String, dynamic>> methods = [];
      try {
        methods = await ApiService.I.getAvailablePaymentMethods();
        _log('طرق الدفع من API: $methods');
      } catch (e) {
        _logError('فشل جلب طرق الدفع من API', e);
        // في حالة الفشل، سنستخدم القيم الافتراضية
      }

      List<PaymentMethod> paymentMethods = methods
          .map((m) => PaymentMethod.fromJson(m))
          .where((m) => m.isActive)
          .toList();
      _log('طرق الدفع المفلترة: ${paymentMethods.map((m) => m.code).toList()}');

      // التحقق من وجود MyFatoorah من الـ API (الوضع المباشر)
      bool hasMyFatoorahFromApi = paymentMethods.any((m) => m.isMyFatoorah);
      bool isTestMode = false;

      // ══════════════════════════════════════════════════════════════════
      // إذا كان MyFatoorah مفعّل من الخادم = الوضع المباشر (Live)
      // إذا لم يكن مفعّل ولكن الوضع التجريبي مفعّل = الوضع التجريبي (Test)
      // ══════════════════════════════════════════════════════════════════
      if (hasMyFatoorahFromApi) {
        // الوضع المباشر - MyFatoorah مفعّل من الخادم
        _log('✅ MyFatoorah مفعّل من الخادم - الوضع المباشر (Live Mode)');
        isTestMode = false;
      } else if (_forceEnableMyFatoorahInTestMode) {
        // الوضع التجريبي - إضافة MyFatoorah يدوياً
        _log('⚠️ MyFatoorah غير موجود في API - إضافته يدوياً للوضع التجريبي');
        paymentMethods.add(const PaymentMethod(
          code: 'myfatoorah',
          name: 'الدفع الإلكتروني',
          nameEn: 'Online Payment (Test Mode)',
          isActive: true,
          icon: 'credit_card',
          supported: ['KNET', 'VISA', 'MasterCard'],
        ));
        isTestMode = true;
      }

      bool hasMyFatoorah = hasMyFatoorahFromApi || (isTestMode && _forceEnableMyFatoorahInTestMode);

      // تحديث Config
      PaymentConfig.updateFromServer(
        isEnabled: hasMyFatoorah,
        isTestMode: isTestMode,
      );

      // إضافة الدفع النقدي إذا لم يكن موجوداً
      if (!paymentMethods.any((m) => m.isCash)) {
        paymentMethods.insert(0, PaymentMethod.cash);
      }

      _methodsState = PaymentMethodsState.loaded(paymentMethods);

      _log('✅ تم تحميل ${paymentMethods.length} طريقة دفع');
      _log('✅ MyFatoorah متاح: $hasMyFatoorah');
      _log('✅ الوضع: ${isTestMode ? "تجريبي (Test)" : "مباشر (Live)"}');

    } catch (e) {
      _logError('فشل تحميل طرق الدفع', e);

      // ══════════════════════════════════════════════════════════════════
      // Fallback: تقديم طرق دفع افتراضية حتى في حالة الخطأ
      // ══════════════════════════════════════════════════════════════════
      if (_forceEnableMyFatoorahInTestMode) {
        _log('⚠️ استخدام طرق الدفع الافتراضية بسبب الخطأ');
        _methodsState = PaymentMethodsState.loaded([
          PaymentMethod.cash,
          PaymentMethod.myfatoorah,
        ]);
        PaymentConfig.updateFromServer(isEnabled: true, isTestMode: true);
      } else {
        _methodsState = PaymentMethodsState.error('فشل تحميل طرق الدفع');
      }
    }

    notifyListeners();
  }

  /// تحديد طريقة الدفع
  void selectPaymentMethod(String method) {
    if (_selectedMethod != method) {
      _selectedMethod = method;
      _log('تم تحديد طريقة الدفع: $method');
      notifyListeners();
    }
  }

  /// تنفيذ الدفع عبر MyFatoorah
  Future<PaymentProcessState> executeMyFatoorahPayment({
    required int orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String countryCode = '+965',
  }) async {
    _processState = const PaymentProcessState.processing();
    notifyListeners();

    try {
      // التحقق من الاتصال (اختياري)
      try {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
          _processState = PaymentProcessState.failed('لا يوجد اتصال بالإنترنت');
          notifyListeners();
          return _processState;
        }
      } catch (e) {
        _log('تجاوز فحص الاتصال: $e');
      }

      _log('تنفيذ الدفع للطلب: $orderId');

      final result = await ApiService.I.executeMyFatoorahPayment(
        orderId: orderId,
        customer: {
          'name': customerName,
          'email': customerEmail,
          'mobile': customerPhone,
          'mobile_country_code': countryCode,
        },
      );

      if (result['ok'] == true && result['payment_url'] != null) {
        _processState = PaymentProcessState.ready(
          paymentUrl: result['payment_url'] as String,
          transactionId: result['transaction_id'] as int?,
          orderId: orderId,
        );
        _log('تم الحصول على رابط الدفع بنجاح');
      } else {
        final errorMessage = _getErrorMessage(result);
        _processState = PaymentProcessState.failed(errorMessage);
        _logError('فشل الدفع', errorMessage);
      }
    } catch (e) {
      _processState = PaymentProcessState.failed('حدث خطأ أثناء عملية الدفع');
      _logError('خطأ في الدفع', e);
    }

    notifyListeners();
    return _processState;
  }

  /// معالجة نتيجة الدفع
  Future<PaymentProcessState> handlePaymentResult({
    required String? result,
    required int? transactionId,
  }) async {
    _processState = const PaymentProcessState.processing();
    notifyListeners();

    try {
      if (transactionId != null) {
        final statusResult = await ApiService.I.getMyFatoorahPaymentStatus(transactionId);

        if (statusResult['ok'] == true) {
          final status = statusResult['status'] as String?;

          if (status == 'paid') {
            _processState = PaymentProcessState.success(
              orderId: statusResult['order_id'] as int?,
            );
          } else if (status == 'failed' || status == 'canceled') {
            _processState = PaymentProcessState.failed(
              statusResult['message'] ?? 'فشلت عملية الدفع',
            );
          } else {
            // حالة قيد المعالجة
            _processState = const PaymentProcessState(
              resultStatus: PaymentResultStatus.pending,
            );
          }
        } else {
          _processState = PaymentProcessState.failed(
            statusResult['message'] ?? 'فشل التحقق من حالة الدفع',
          );
        }
      } else if (result == 'success') {
        _processState = const PaymentProcessState(
          resultStatus: PaymentResultStatus.success,
        );
      } else {
        _processState = PaymentProcessState.failed('فشلت عملية الدفع');
      }
    } catch (e) {
      _processState = PaymentProcessState.failed('خطأ في التحقق من حالة الدفع');
      _logError('خطأ في معالجة النتيجة', e);
    }

    notifyListeners();
    return _processState;
  }

  /// إعادة تعيين حالة الدفع
  void resetPaymentProcess() {
    _processState = const PaymentProcessState.initial();
    notifyListeners();
  }

  /// الحصول على رسالة الخطأ المناسبة
  String _getErrorMessage(Map<String, dynamic> result) {
    final errorType = result['error_type'] as String?;
    final message = result['message'] as String?;

    switch (errorType) {
      case 'TOKEN_INVALID':
        return 'بوابة الدفع غير متاحة حالياً. يمكنك اختيار الدفع عند الاستلام.';
      case 'SSL_ERROR':
        return 'مشكلة في الاتصال الآمن. حاول مرة أخرى.';
      case 'NETWORK_ERROR':
        return 'تعذّر الاتصال ببوابة الدفع. تحقق من اتصالك بالإنترنت.';
      default:
        return message ?? 'حدث خطأ أثناء عملية الدفع';
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[PaymentProvider] $message');
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('[PaymentProvider] ERROR: $message - $error');
    }
  }
}
