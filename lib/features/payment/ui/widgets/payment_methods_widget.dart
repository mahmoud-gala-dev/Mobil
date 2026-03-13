import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/payment_config.dart';
import '../../state/payment_provider.dart';

/// ويدجت اختيار طرق الدفع
class PaymentMethodsWidget extends StatelessWidget {
  final Function(String)? onMethodChanged;

  const PaymentMethodsWidget({
    super.key,
    this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<PaymentProvider>(
      builder: (context, provider, _) {
        final state = provider.methodsState;

        // حالة التحميل
        if (state.isLoading) {
          return _buildLoadingState(isDark);
        }

        // حالة الخطأ أو عدم الاتصال
        if (state.hasError || state.isOffline) {
          return _buildErrorState(
            context,
            state.errorMessage ?? 'حدث خطأ',
            state.isOffline,
            provider,
            isDark,
            colorScheme,
          );
        }

        // عرض طرق الدفع
        return _buildPaymentMethods(
          context,
          provider,
          isDark,
          colorScheme,
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('جارٍ تحميل طرق الدفع...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    bool isOffline,
    PaymentProvider provider,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOffline ? Colors.orange : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isOffline ? Icons.wifi_off : Icons.error_outline,
                color: isOffline ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => provider.loadPaymentMethods(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
          const Divider(height: 24),
          // عرض الدفع عند الاستلام كخيار افتراضي
          _buildCashOption(context, provider, isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(
    BuildContext context,
    PaymentProvider provider,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final methods = provider.availableMethods;
    final selectedMethod = provider.selectedMethod;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // شارة الوضع التجريبي
          if (PaymentConfig.isTestMode && provider.isMyFatoorahEnabled)
            _buildTestModeBanner(isDark),

          // طرق الدفع
          ...methods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            final isFirst = index == 0;
            final isLast = index == methods.length - 1;
            final isSelected = selectedMethod == method.code;

            return Column(
              children: [
                if (!isFirst)
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                _buildMethodTile(
                  context,
                  method,
                  isSelected,
                  isFirst,
                  isLast,
                  provider,
                  isDark,
                  colorScheme,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestModeBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 6),
          Text(
            'الوضع التجريبي - لا يتم خصم مبالغ حقيقية',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(
    BuildContext context,
    PaymentMethod method,
    bool isSelected,
    bool isFirst,
    bool isLast,
    PaymentProvider provider,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        provider.selectPaymentMethod(method.code);
        onMethodChanged?.call(method.code);
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(15) : Radius.zero,
            bottom: isLast ? const Radius.circular(15) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            // أيقونة طريقة الدفع
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : isDark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                method.isCash ? Icons.money : Icons.credit_card,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.grey[300]
                        : Colors.grey[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // معلومات طريقة الدفع
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? colorScheme.primary
                              : isDark
                                  ? Colors.white
                                  : Colors.grey[800],
                        ),
                      ),
                      if (method.isMyFatoorah) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue[900] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MyFatoorah',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.blue[300] : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.isCash
                        ? 'ادفع نقداً عند استلام الطلب'
                        : 'ادفع باستخدام ${method.supported.join(' أو ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  // شارات البطاقات المدعومة
                  if (method.isMyFatoorah && method.supported.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: method.supported.map((card) {
                        return _buildCardBadge(card, isDark);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // علامة الاختيار
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashOption(
    BuildContext context,
    PaymentProvider provider,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return _buildMethodTile(
      context,
      PaymentMethod.cash,
      true,
      true,
      true,
      provider,
      isDark,
      colorScheme,
    );
  }

  Widget _buildCardBadge(String card, bool isDark) {
    Color color;
    switch (card.toUpperCase()) {
      case 'KNET':
        color = Colors.blue;
        break;
      case 'VISA':
        color = Colors.indigo;
        break;
      case 'MASTERCARD':
      case 'MC':
        color = Colors.orange;
        break;
      case 'APPLE PAY':
        color = isDark ? Colors.white : Colors.black;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        card,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
