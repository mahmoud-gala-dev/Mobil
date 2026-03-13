import 'entities/payment_method.dart';

/// حالات الدفع
enum PaymentLoadingState {
  initial,
  loading,
  loaded,
  error,
  offline,
}

/// حالة طرق الدفع المتاحة
class PaymentMethodsState {
  final PaymentLoadingState loadingState;
  final List<PaymentMethod> methods;
  final String? errorMessage;
  final bool isOffline;

  const PaymentMethodsState({
    this.loadingState = PaymentLoadingState.initial,
    this.methods = const [],
    this.errorMessage,
    this.isOffline = false,
  });

  /// الحالة الأولية
  const PaymentMethodsState.initial()
      : loadingState = PaymentLoadingState.initial,
        methods = const [],
        errorMessage = null,
        isOffline = false;

  /// حالة التحميل
  const PaymentMethodsState.loading()
      : loadingState = PaymentLoadingState.loading,
        methods = const [],
        errorMessage = null,
        isOffline = false;

  /// حالة النجاح
  PaymentMethodsState.loaded(this.methods)
      : loadingState = PaymentLoadingState.loaded,
        errorMessage = null,
        isOffline = false;

  /// حالة الخطأ
  PaymentMethodsState.error(this.errorMessage)
      : loadingState = PaymentLoadingState.error,
        methods = const [PaymentMethod.cash],
        isOffline = false;

  /// حالة عدم الاتصال
  const PaymentMethodsState.offline()
      : loadingState = PaymentLoadingState.offline,
        methods = const [PaymentMethod.cash],
        errorMessage = 'لا يوجد اتصال بالإنترنت',
        isOffline = true;

  /// هل MyFatoorah متاح؟
  bool get isMyFatoorahEnabled =>
      methods.any((m) => m.code == 'myfatoorah' && m.isActive);

  /// هل يتم التحميل؟
  bool get isLoading => loadingState == PaymentLoadingState.loading;

  /// هل تم التحميل؟
  bool get isLoaded => loadingState == PaymentLoadingState.loaded;

  /// هل هناك خطأ؟
  bool get hasError => loadingState == PaymentLoadingState.error;

  /// نسخة جديدة مع تغييرات
  PaymentMethodsState copyWith({
    PaymentLoadingState? loadingState,
    List<PaymentMethod>? methods,
    String? errorMessage,
    bool? isOffline,
  }) {
    return PaymentMethodsState(
      loadingState: loadingState ?? this.loadingState,
      methods: methods ?? this.methods,
      errorMessage: errorMessage ?? this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

/// حالة عملية الدفع
class PaymentProcessState {
  final bool isProcessing;
  final String? paymentUrl;
  final int? transactionId;
  final int? orderId;
  final String? errorMessage;
  final PaymentResultStatus? resultStatus;

  const PaymentProcessState({
    this.isProcessing = false,
    this.paymentUrl,
    this.transactionId,
    this.orderId,
    this.errorMessage,
    this.resultStatus,
  });

  const PaymentProcessState.initial()
      : isProcessing = false,
        paymentUrl = null,
        transactionId = null,
        orderId = null,
        errorMessage = null,
        resultStatus = null;

  const PaymentProcessState.processing()
      : isProcessing = true,
        paymentUrl = null,
        transactionId = null,
        orderId = null,
        errorMessage = null,
        resultStatus = null;

  PaymentProcessState.ready({
    required this.paymentUrl,
    required this.transactionId,
    required this.orderId,
  })  : isProcessing = false,
        errorMessage = null,
        resultStatus = null;

  PaymentProcessState.failed(this.errorMessage)
      : isProcessing = false,
        paymentUrl = null,
        transactionId = null,
        orderId = null,
        resultStatus = PaymentResultStatus.failed;

  PaymentProcessState.success({this.orderId})
      : isProcessing = false,
        paymentUrl = null,
        transactionId = null,
        errorMessage = null,
        resultStatus = PaymentResultStatus.success;

  bool get hasError => errorMessage != null;
  bool get isReady => paymentUrl != null;
  bool get isSuccess => resultStatus == PaymentResultStatus.success;
  bool get isFailed => resultStatus == PaymentResultStatus.failed;
}

/// نتيجة عملية الدفع
enum PaymentResultStatus {
  success,
  failed,
  pending,
  cancelled,
}
