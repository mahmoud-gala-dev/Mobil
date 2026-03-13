/// كيان طريقة الدفع
class PaymentMethod {
  final String code;
  final String name;
  final String nameEn;
  final bool isActive;
  final String? icon;
  final List<String> supported;

  const PaymentMethod({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.isActive,
    this.icon,
    this.supported = const [],
  });

  /// الدفع عند الاستلام
  static const cash = PaymentMethod(
    code: 'cash',
    name: 'الدفع عند الاستلام',
    nameEn: 'Cash on Delivery',
    isActive: true,
    icon: 'money',
  );

  /// الدفع الإلكتروني عبر MyFatoorah
  static const myfatoorah = PaymentMethod(
    code: 'myfatoorah',
    name: 'الدفع الإلكتروني',
    nameEn: 'Online Payment',
    isActive: true,
    icon: 'credit_card',
    supported: ['KNET', 'VISA', 'MasterCard', 'Apple Pay'],
  );

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      icon: json['icon'] as String?,
      supported: (json['supported'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'name_en': nameEn,
        'is_active': isActive,
        'icon': icon,
        'supported': supported,
      };

  bool get isMyFatoorah => code == 'myfatoorah';
  bool get isCash => code == 'cash';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
