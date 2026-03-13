import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/myfatoorah_service.dart';
import '../../state/cart_provider.dart';

/// صفحة نتيجة الدفع
/// تُعرض بعد الرجوع من بوابة الدفع MyFatoorah
class PaymentResultScreen extends StatefulWidget {
  final String? result;
  final int? orderId;
  final int? transactionId;
  final String? errorCode;

  const PaymentResultScreen({
    super.key,
    this.result,
    this.orderId,
    this.transactionId,
    this.errorCode,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  PaymentStatus? _paymentStatus;
  String? _errorMessage;
  String? _orderNumber;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _checkPaymentStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    print('[PaymentResult] Checking payment status...');
    print('  result: ${widget.result}');
    print('  orderId: ${widget.orderId}');
    print('  transactionId: ${widget.transactionId}');
    print('  errorCode: ${widget.errorCode}');

    setState(() => _isLoading = true);

    try {
      // إذا كان هناك transactionId، نستعلم عن الحالة من الخادم
      if (widget.transactionId != null) {
        final result = await ApiService.I.getMyFatoorahPaymentStatus(widget.transactionId!);

        if (result['ok'] == true) {
          final status = PaymentStatus.fromString(result['status'] ?? 'pending');
          _paymentStatus = status;

          if (status == PaymentStatus.paid) {
            // تحديث السلة عند نجاح الدفع
            if (mounted) {
              context.read<CartProvider>().refresh();
            }
          }

          // جلب رقم الطلب
          if (result['order_id'] != null) {
            try {
              final orderData = await ApiService.I.orderDetails(result['order_id']);
              _orderNumber = orderData['data']?['order_number'] ?? orderData['order']?['order_number'];
            } catch (_) {}
          }
        } else {
          _paymentStatus = PaymentStatus.failed;
          _errorMessage = result['message'];
        }
      } else if (widget.result == 'success') {
        _paymentStatus = PaymentStatus.paid;
        if (mounted) {
          context.read<CartProvider>().refresh();
        }
      } else if (widget.result == 'error') {
        _paymentStatus = PaymentStatus.failed;
        _errorMessage = _getErrorMessage(widget.errorCode);
      } else {
        _paymentStatus = PaymentStatus.pending;
      }

      _animationController.forward();
    } catch (e) {
      print('[PaymentResult] Error: $e');
      _paymentStatus = PaymentStatus.failed;
      _errorMessage = 'حدث خطأ أثناء التحقق من حالة الدفع';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String? errorCode) {
    switch (errorCode) {
      case 'missing_payment_id':
        return 'معرف الدفع مفقود';
      case 'payment_failed':
        return 'فشلت عملية الدفع';
      case 'callback_exception':
        return 'حدث خطأ أثناء معالجة الدفع';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة الدفع'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري التحقق من حالة الدفع...'),
                ],
              ),
            )
          : _buildResultContent(colorScheme),
    );
  }

  Widget _buildResultContent(ColorScheme colorScheme) {
    final isPaid = _paymentStatus == PaymentStatus.paid;
    final isFailed = _paymentStatus == PaymentStatus.failed ||
                     _paymentStatus == PaymentStatus.canceled;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة النتيجة المتحركة
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPaid
                      ? Colors.green.withOpacity(0.1)
                      : isFailed
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle
                      : isFailed
                          ? Icons.cancel
                          : Icons.hourglass_empty,
                  size: 80,
                  color: isPaid
                      ? Colors.green
                      : isFailed
                          ? Colors.red
                          : Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // العنوان
            Text(
              isPaid
                  ? 'تم الدفع بنجاح!'
                  : isFailed
                      ? 'فشلت عملية الدفع'
                      : 'جاري معالجة الدفع',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isPaid
                    ? Colors.green[700]
                    : isFailed
                        ? Colors.red[700]
                        : Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // الوصف
            Text(
              isPaid
                  ? 'شكراً لك! تم استلام دفعتك بنجاح وسيتم تجهيز طلبك قريباً.'
                  : isFailed
                      ? _errorMessage ?? 'لم تتم عملية الدفع. يمكنك المحاولة مرة أخرى.'
                      : 'يتم معالجة دفعتك. سيتم تحديث حالة الطلب تلقائياً.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // معلومات الطلب
            if (isPaid && (_orderNumber != null || widget.orderId != null))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    if (_orderNumber != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'رقم الطلب:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _orderNumber!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'حالة الدفع:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'مدفوع',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // الأزرار
            if (isPaid) ...[
              // زر تتبع الطلب
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_orderNumber != null) {
                      context.go('/order-track/$_orderNumber');
                    } else if (widget.orderId != null) {
                      context.go('/orders');
                    } else {
                      context.go('/orders');
                    }
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('تتبع الطلب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // زر العودة للرئيسية
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('العودة للرئيسية'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else if (isFailed) ...[
              // زر المحاولة مرة أخرى
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/checkout'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('المحاولة مرة أخرى'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // زر الدفع عند الاستلام
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // العودة للـ checkout مع تحديد الدفع عند الاستلام
                    context.go('/checkout?payment=cash');
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('الدفع عند الاستلام'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // زر العودة للرئيسية
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('العودة للرئيسية'),
              ),
            ] else ...[
              // حالة قيد المعالجة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkPaymentStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث الحالة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('عرض طلباتي'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
