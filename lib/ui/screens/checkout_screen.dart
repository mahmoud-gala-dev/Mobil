import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../state/cart_provider.dart';
import '../../state/auth_provider.dart';
import '../../models/models.dart';
import '../../features/payment/state/payment_provider.dart';
import '../../features/payment/ui/widgets/payment_methods_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  int _currentStep = 0;
  bool _isLoading = true;
  bool _submitting = false;
  bool _isLoadingCities = false;

  // Data
  List<AddressModel> _savedAddresses = [];
  AddressModel? _selectedAddress;
  String _deliveryType = 'immediate';
  String _paymentMethod = 'cash';

  // Location
  List<Map<String, dynamic>> _governorates = [];
  List<Map<String, dynamic>> _cities = [];
  String? _selectedGovernorate;
  int? _selectedGovernorateId;
  String? _selectedCity;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      provider.selectPaymentMethod(_paymentMethod);
      provider.loadPaymentMethods();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();

      if (!auth.isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('يجب تسجيل الدخول أولاً لإتمام الطلب')),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.go('/auth/customer/login');
        }
        return;
      }

      // Load user data
      if (auth.user != null) {
        try {
          final userData = await ApiService.I.me();
          final u = userData['user'] as Map<String, dynamic>?;
          if (u != null) {
            _nameController.text = (u['name'] ?? '').toString().trim();
            _emailController.text = (u['email'] ?? '').toString().trim();
            _phoneController.text = (u['phone'] ?? '').toString().trim();
          }
        } catch (e) {
          _nameController.text = auth.user!.name;
          _emailController.text = auth.user!.email;
          _phoneController.text = auth.user!.phone ?? '';
        }
      }

      // Load governorates
      try {
        final govs = await ApiService.I.getGovernorates();
        final uniqueGovs = <String, Map<String, dynamic>>{};
        for (var gov in govs) {
          final name = gov['name_ar'] as String?;
          if (name != null && !uniqueGovs.containsKey(name)) {
            uniqueGovs[name] = gov;
          }
        }
        _governorates = uniqueGovs.values.toList();
      } catch (e) {
        debugPrint('Error loading governorates: $e');
      }

      // Load saved addresses
      try {
        final addresses = await ApiService.I.getAddresses();
        _savedAddresses = addresses.map((a) => AddressModel.fromApi(a)).toList();

        if (_savedAddresses.isNotEmpty) {
          final defaultAddr = _savedAddresses.where((a) => a.isDefault).toList();
          _selectedAddress =
              defaultAddr.isNotEmpty ? defaultAddr.first : _savedAddresses.first;
          _selectAddress(_selectedAddress!);
        }
      } catch (e) {
        debugPrint('No saved addresses: $e');
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    }
  }

  void _selectAddress(AddressModel address) async {
    setState(() {
      _selectedAddress = address;
      _selectedGovernorate = address.governorate;
      _selectedCity = address.city;
      _addressController.text = address.address;
    });

    if (_selectedGovernorate != null) {
      final gov = _governorates.firstWhere(
        (g) => g['name_ar'] == _selectedGovernorate,
        orElse: () => <String, dynamic>{},
      );
      if (gov.isNotEmpty) {
        _selectedGovernorateId = (gov['id'] as num?)?.toInt();
        await _loadCities();
      }
    }
  }

  Future<void> _loadCities() async {
    if (_selectedGovernorateId == null) return;
    setState(() => _isLoadingCities = true);

    try {
      final cities = await ApiService.I.getCities(governorateId: _selectedGovernorateId!);
      final uniqueCities = <String, Map<String, dynamic>>{};
      for (var city in cities) {
        final name = city['name_ar'] as String?;
        if (name != null && !uniqueCities.containsKey(name)) {
          uniqueCities[name] = city;
        }
      }
      _cities = uniqueCities.values.toList();
    } catch (e) {
      debugPrint('Error loading cities: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // معلومات العميل
        return _nameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _emailController.text.contains('@') &&
            _phoneController.text.trim().isNotEmpty;
      case 1: // عنوان التوصيل
        return _selectedGovernorate != null &&
            _selectedCity != null &&
            _addressController.text.trim().isNotEmpty;
      case 2: // طريقة الدفع
        return true; // Always valid - default is cash
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      HapticFeedback.selectionClick();
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      }
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('يرجى إكمال جميع الحقول المطلوبة'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _previousStep() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final apiPaymentMethod =
          paymentProvider.selectedMethod == 'myfatoorah' ? 'myfatoorah' : 'cash';

      final res = await ApiService.I.checkout(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        deliveryAddress: _addressController.text,
        deliveryCity: _selectedCity ?? '',
        deliveryGovernorate: _selectedGovernorate ?? '',
        deliveryNotes:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        deliveryType: _deliveryType,
        paymentMethod: apiPaymentMethod,
      );

      if (!mounted) return;

      final orders = res['orders'] as List?;
      final firstOrder = orders?.isNotEmpty == true ? orders!.first : null;
      final orderId = firstOrder?['id'] as int?;
      final orderNumber = firstOrder?['order_number'] as String?;

      if (apiPaymentMethod == 'myfatoorah' && orderId != null) {
        await _processMyFatoorahPayment(orderId, orderNumber);
      } else {
        context.read<CartProvider>().refresh();
        _showSuccessAndNavigate(orderNumber);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('فشل إنشاء الطلب: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _processMyFatoorahPayment(int orderId, String? orderNumber) async {
    final paymentProvider = context.read<PaymentProvider>();

    final result = await paymentProvider.executeMyFatoorahPayment(
      orderId: orderId,
      customerName: _nameController.text,
      customerEmail: _emailController.text,
      customerPhone: _phoneController.text,
    );

    if (!mounted) return;

    if (result.isReady && result.paymentUrl != null) {
      final encodedUrl = Uri.encodeComponent(result.paymentUrl!);
      final tx = result.transactionId ?? 0;
      context.push('/payment/webview?url=$encodedUrl&orderId=$orderId&tx=$tx');
    } else {
      _showPaymentErrorDialog(result.errorMessage, orderNumber);
    }
  }

  void _showPaymentErrorDialog(String? errorMessage, String? orderNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 12),
            const Text('تعذّر الدفع الإلكتروني'),
          ],
        ),
        content: Text(errorMessage ?? 'حدث خطأ في بوابة الدفع'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PaymentProvider>().selectPaymentMethod('cash');
            },
            child: const Text('الدفع عند الاستلام'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndNavigate(String? orderNumber) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('تم إنشاء الطلب بنجاح'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (orderNumber != null) {
      context.go('/order-track/$orderNumber');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: _buildAppBar(colorScheme),
      body: _isLoading
          ? _buildLoadingState(colorScheme)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Progress Indicator
                    _CheckoutProgress(
                      currentStep: _currentStep,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),

                    // Step Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildStepContent(colorScheme, isDark, cart),
                      ),
                    ),

                    // Bottom Actions
                    _buildBottomActions(colorScheme, isDark, cart),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      title: const Text(
        'إتمام الطلب',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جارٍ تحميل البيانات...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    ColorScheme colorScheme,
    bool isDark,
    CartProvider cart,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildCustomerInfoStep(colorScheme, isDark);
      case 1:
        return _buildAddressStep(colorScheme, isDark);
      case 2:
        return _buildPaymentStep(colorScheme, isDark);
      case 3:
        return _buildReviewStep(colorScheme, isDark, cart);
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 1: Customer Info
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCustomerInfoStep(ColorScheme colorScheme, bool isDark) {
    return _StepCard(
      title: 'معلومات العميل',
      icon: Icons.person_rounded,
      colorScheme: colorScheme,
      isDark: isDark,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Icons.person_outline_rounded,
            validator: (v) => v?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'الرجاء إدخال البريد الإلكتروني';
              if (!v!.contains('@')) return 'البريد الإلكتروني غير صحيح';
              return null;
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v?.isEmpty ?? true ? 'الرجاء إدخال رقم الهاتف' : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 2: Address
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAddressStep(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Saved Addresses
        if (_savedAddresses.isNotEmpty) ...[
          _StepCard(
            title: 'العناوين المحفوظة',
            icon: Icons.bookmark_rounded,
            colorScheme: colorScheme,
            isDark: isDark,
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _savedAddresses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final addr = _savedAddresses[i];
                  final isSelected = _selectedAddress?.id == addr.id;
                  return _SavedAddressCard(
                    address: addr,
                    isSelected: isSelected,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onTap: () => _selectAddress(addr),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Address Form
        _StepCard(
          title: 'عنوان التوصيل',
          icon: Icons.location_on_rounded,
          colorScheme: colorScheme,
          isDark: isDark,
          child: Column(
            children: [
              // Governorate
              _buildDropdown(
                value: _selectedGovernorate,
                label: 'المحافظة',
                icon: Icons.map_outlined,
                items: _governorates
                    .map((g) => g['name_ar'] as String? ?? '')
                    .toList(),
                onChanged: (value) async {
                  final gov = _governorates.firstWhere(
                    (g) => g['name_ar'] == value,
                    orElse: () => <String, dynamic>{},
                  );
                  setState(() {
                    _selectedGovernorate = value;
                    _selectedGovernorateId = (gov['id'] as num?)?.toInt();
                    _selectedCity = null;
                    _cities = [];
                  });
                  if (_selectedGovernorateId != null) await _loadCities();
                },
                isDark: isDark,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),

              // City
              _buildDropdown(
                value: _selectedCity,
                label: 'المدينة',
                icon: Icons.location_city_outlined,
                items:
                    _cities.map((c) => c['name_ar'] as String? ?? '').toList(),
                onChanged: (value) => setState(() => _selectedCity = value),
                enabled: _selectedGovernorate != null && !_isLoadingCities,
                isLoading: _isLoadingCities,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),

              // Detailed Address
              _buildTextField(
                controller: _addressController,
                label: 'العنوان التفصيلي',
                icon: Icons.home_outlined,
                maxLines: 2,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'الرجاء إدخال العنوان' : null,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                controller: _notesController,
                label: 'ملاحظات إضافية (اختياري)',
                icon: Icons.note_outlined,
                maxLines: 2,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 3: Payment
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentStep(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Delivery Type
        _StepCard(
          title: 'نوع التوصيل',
          icon: Icons.local_shipping_rounded,
          colorScheme: colorScheme,
          isDark: isDark,
          child: Row(
            children: [
              Expanded(
                child: _DeliveryTypeOption(
                  title: 'فوري',
                  subtitle: 'توصيل سريع',
                  icon: Icons.flash_on_rounded,
                  isSelected: _deliveryType == 'immediate',
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onTap: () => setState(() => _deliveryType = 'immediate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DeliveryTypeOption(
                  title: 'مجدول',
                  subtitle: 'حدد موعداً',
                  icon: Icons.schedule_rounded,
                  isSelected: _deliveryType == 'scheduled',
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onTap: () => setState(() => _deliveryType = 'scheduled'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Methods
        _StepCard(
          title: 'طريقة الدفع',
          icon: Icons.payment_rounded,
          colorScheme: colorScheme,
          isDark: isDark,
          child: PaymentMethodsWidget(
            onMethodChanged: (method) {
              setState(() => _paymentMethod = method);
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 4: Review
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReviewStep(
    ColorScheme colorScheme,
    bool isDark,
    CartProvider cart,
  ) {
    final subtotal = cart.subtotal;
    final delivery = subtotal >= 10 ? 0.0 : 1.5;
    final vat = subtotal * 0.15;
    final total = subtotal + delivery + vat;

    return Column(
      children: [
        // Order Summary
        _StepCard(
          title: 'ملخص الطلب',
          icon: Icons.receipt_long_rounded,
          colorScheme: colorScheme,
          isDark: isDark,
          child: Column(
            children: [
              ...cart.items.values.map((item) => _OrderItemRow(
                    item: item,
                    isDark: isDark,
                  )),
              const Divider(height: 24),
              _PriceRow(label: 'المجموع الفرعي', value: subtotal, isDark: isDark),
              const SizedBox(height: 8),
              _PriceRow(
                label: 'التوصيل',
                value: delivery,
                isFree: delivery == 0,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _PriceRow(label: 'الضريبة (15%)', value: vat, isDark: isDark),
              const Divider(height: 24),
              _PriceRow(
                label: 'الإجمالي',
                value: total,
                isTotal: true,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delivery Info
        _StepCard(
          title: 'معلومات التوصيل',
          icon: Icons.local_shipping_outlined,
          colorScheme: colorScheme,
          isDark: isDark,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'الاسم',
                value: _nameController.text,
                isDark: isDark,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'الهاتف',
                value: _phoneController.text,
                isDark: isDark,
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'العنوان',
                value:
                    '${_addressController.text}, $_selectedCity, $_selectedGovernorate',
                isDark: isDark,
              ),
              _InfoRow(
                icon: Icons.payment_outlined,
                label: 'الدفع',
                value: _paymentMethod == 'cash' ? 'عند الاستلام' : 'إلكتروني',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bottom Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomActions(
    ColorScheme colorScheme,
    bool isDark,
    CartProvider cart,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('السابق'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),

            // Next/Submit Button
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : (_currentStep < 3 ? _nextStep : _submitOrder),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep < 3 ? 'التالي' : 'تأكيد الطلب',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep < 3
                                ? Icons.arrow_back_rounded
                                : Icons.check_rounded,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
    bool isLoading = false,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (v) => v == null ? 'الرجاء الاختيار' : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Supporting Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _CheckoutProgress extends StatelessWidget {
  final int currentStep;
  final ColorScheme colorScheme;
  final bool isDark;

  const _CheckoutProgress({
    required this.currentStep,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final steps = ['المعلومات', 'العنوان', 'الدفع', 'المراجعة'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector
            final stepIndex = index ~/ 2;
            final isCompleted = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted ? colorScheme.primary : Colors.grey[300],
              ),
            );
          } else {
            // Step
            final stepIndex = index ~/ 2;
            final isActive = currentStep == stepIndex;
            final isCompleted = currentStep > stepIndex;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? colorScheme.primary
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? colorScheme.primary : Colors.grey[600],
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final ColorScheme colorScheme;
  final bool isDark;

  const _StepCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  const _SavedAddressCard({
    required this.address,
    required this.isSelected,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: isSelected ? colorScheme.primary : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'افتراضي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              address.address,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  const _DeliveryTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItem item;
  final bool isDark;

  const _OrderItemRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.image,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'x${item.qty}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${(item.product.price * item.qty).toStringAsFixed(2)} د.ع',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isFree;
  final bool isTotal;
  final ColorScheme? colorScheme;
  final bool isDark;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isFree = false,
    this.isTotal = false,
    this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        Text(
          isFree ? 'مجاني' : '${value.toStringAsFixed(2)} د.ع',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isFree
                ? Colors.green
                : (isTotal ? colorScheme?.primary : null),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
