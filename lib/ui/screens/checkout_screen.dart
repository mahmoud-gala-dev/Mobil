import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../state/cart_provider.dart';
import '../../state/auth_provider.dart';
import '../../models/models.dart';
import '../widgets/app_drawer.dart';
import '../../features/payment/state/payment_provider.dart';
import '../../features/payment/ui/widgets/payment_methods_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  
  bool _isLoading = true;
  bool _submitting = false;
  bool _isLoadingCities = false;

  List<AddressModel> _savedAddresses = [];
  AddressModel? _selectedAddress;
  String _deliveryType = 'immediate';
  String _paymentMethod = 'cash';
  
  // للمحافظات والمدن
  List<Map<String, dynamic>> _governorates = [];
  List<Map<String, dynamic>> _cities = [];
  String? _selectedGovernorate;
  int? _selectedGovernorateId;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    print('🛒 [Checkout] تهيئة صفحة إتمام الطلب...');
    _loadUserData();
    // تحميل طرق الدفع باستخدام PaymentProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      provider.selectPaymentMethod(_paymentMethod);
      provider.loadPaymentMethods();
    });
  }

  Future<void> _loadUserData() async {
    print('📥 [Checkout] جلب بيانات المستخدم...');
    setState(() => _isLoading = true);
    
    try {
      // التحقق من تسجيل الدخول أولاً
      final auth = context.read<AuthProvider>();
      
      if (!auth.isAuthenticated) {
        print('⚠️ [Checkout] المستخدم غير مسجل دخول، التحويل لصفحة تسجيل الدخول');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('يجب تسجيل الدخول أولاً لإتمام الطلب'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            context.go('/auth/customer/login');
          }
        }
        return;
      }
      
      // ملء البيانات من المستخدم المسجل دخول
      if (auth.isAuthenticated && auth.user != null) {
        // جلب البيانات المحدثة من API
        try {
          final userData = await ApiService.I.me();
          final u = userData['user'] as Map<String, dynamic>?;
          if (u != null) {
            _name.text = (u['name'] ?? '').toString().trim();
            _email.text = (u['email'] ?? '').toString().trim();
            final phoneValue = u['phone'];
            _phone.text = (phoneValue != null && phoneValue.toString().trim().isNotEmpty) 
                ? phoneValue.toString().trim() 
                : '';
          }
        } catch (e) {
          print('⚠️ [Checkout] فشل جلب البيانات من API، استخدام البيانات المحفوظة: $e');
          _name.text = auth.user!.name;
          _email.text = auth.user!.email;
          final phoneValue = auth.user!.phone;
          _phone.text = (phoneValue != null && phoneValue.trim().isNotEmpty) 
              ? phoneValue.trim() 
              : '';
        }
        
        print('✅ [Checkout] تم تعبئة البيانات من المستخدم:');
        print('   الاسم: ${_name.text}');
        print('   البريد: ${_email.text}');
        print('   الهاتف: ${_phone.text}');
      } else {
        print('⚠️ [Checkout] المستخدم غير مسجل دخول');
      }
      
      // جلب المحافظات
      try {
        final govs = await ApiService.I.getGovernorates();
        // التأكد من عدم وجود تكرار في الأسماء
        final uniqueGovs = <String, Map<String, dynamic>>{};
        for (var gov in govs) {
          final name = gov['name_ar'] as String?;
          if (name != null && !uniqueGovs.containsKey(name)) {
            uniqueGovs[name] = gov;
          }
        }
        _governorates = uniqueGovs.values.toList();
        print('✅ [Checkout] تم جلب ${_governorates.length} محافظة فريدة');
      } catch (e) {
        print('❌ [Checkout] فشل جلب المحافظات: $e');
      }
      
      // جلب العناوين المحفوظة
      try {
        final addresses = await ApiService.I.getAddresses();
        _savedAddresses = addresses.map((a) => AddressModel.fromApi(a)).toList();
        
        // اختيار العنوان الافتراضي تلقائياً
        if (_savedAddresses.isNotEmpty) {
          final defaultAddresses = _savedAddresses.where((a) => a.isDefault).toList();
          _selectedAddress = defaultAddresses.isNotEmpty 
              ? defaultAddresses.first 
              : _savedAddresses.first;
          
          _selectedGovernorate = _selectedAddress!.governorate;
          _selectedCity = _selectedAddress!.city;
          _address.text = _selectedAddress!.address;

          // فلترة أولية للقيم غير الصالحة
          if (_selectedCity == 'Voluptate velit exer.') {
            print('⚠️ [Checkout] تم العثور على قيمة مدينة غير صالحة، سيتم تجاهلها.');
            _selectedCity = null;
          }

          // التحقق من أن المحافظة المحددة موجودة في القائمة
          if (_selectedGovernorate != null && !_governorates.any((g) => g['name_ar'] == _selectedGovernorate)) {
            print('⚠️ [Checkout] المحافظة المحفوظة "$_selectedGovernorate" غير موجودة في القائمة، سيتم إعادة تعيينها');
            _selectedGovernorate = null;
            _selectedCity = null; // Reset city as well
          }
          
          // جلب المدن للمحافظة المحددة
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
          
          print('✅ [Checkout] تم تحديد العنوان الافتراضي: ${_selectedAddress!.label}');
        }
        
        print('✅ [Checkout] تم جلب ${_savedAddresses.length} عنوان محفوظ');
      } catch (e) {
        print('⚠️ [Checkout] لا توجد عناوين محفوظة: $e');
      }

      // طرق الدفع يتم تحميلها عبر PaymentProvider في initState
    } catch (e) {
      print('❌ [Checkout] خطأ في جلب البيانات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadCities() async {
    if (_selectedGovernorateId == null) return;

    setState(() => _isLoadingCities = true);

    try {
      final citiesFromApi = await ApiService.I.getCities(governorateId: _selectedGovernorateId);
      // التأكد من عدم وجود تكرار في الأسماء
      final uniqueCities = <String, Map<String, dynamic>>{};
      for (var city in citiesFromApi) {
        final name = city['name_ar'] as String?;
        if (name != null && !uniqueCities.containsKey(name)) {
          uniqueCities[name] = city;
        }
      }
      _cities = uniqueCities.values.toList();

      // التحقق من أن المدينة المحددة لا تزال موجودة
      if (_selectedCity != null && !_cities.any((c) => c['name_ar'] == _selectedCity)) {
        print('⚠️ [Checkout] المدينة المحفوظة "$_selectedCity" غير موجودة في القائمة، سيتم إعادة تعيينها');
        _selectedCity = null;
      }

      print('✅ [Checkout] تم جلب ${_cities.length} مدينة فريدة للمحافظة $_selectedGovernorate');
    } catch (e) {
      print('❌ [Checkout] فشل جلب المدن: $e');
      _cities = [];
      _selectedCity = null;
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    print('📤 [Checkout] محاولة إرسال الطلب...');

    if (!_formKey.currentState!.validate()) {
      print('⚠️ [Checkout] فشل التحقق من صحة النموذج');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعبئة جميع الحقول المطلوبة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      print('🚀 [Checkout] إرسال البيانات إلى API...');
      print('   الاسم: ${_name.text}');
      print('   البريد: ${_email.text}');
      print('   الهاتف: ${_phone.text}');
      print('   المحافظة: $_selectedGovernorate');
      print('   المدينة: $_selectedCity');
      print('   العنوان: ${_address.text}');
      print('   طريقة الدفع: $_paymentMethod');

      // تحديد طريقة الدفع للـ API
      final apiPaymentMethod = _paymentMethod == 'myfatoorah' ? 'myfatoorah' : 'cash';

      final res = await ApiService.I.checkout(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        deliveryAddress: _address.text,
        deliveryCity: _selectedCity ?? '',
        deliveryGovernorate: _selectedGovernorate ?? '',
        deliveryNotes: _notes.text.isNotEmpty ? _notes.text : null,
        deliveryType: _deliveryType,
        paymentMethod: apiPaymentMethod,
      );

      print('✅ [Checkout] تم إنشاء الطلب بنجاح!');

      if (!mounted) return;

      // استخراج معلومات الطلب
      final orders = res['orders'] as List?;
      final firstOrder = orders?.isNotEmpty == true ? orders!.first : null;
      final orderId = firstOrder?['id'] as int?;
      final orderNumber = firstOrder?['order_number'] as String?;

      // إذا كانت طريقة الدفع MyFatoorah، ننتقل للدفع الإلكتروني
      if (_paymentMethod == 'myfatoorah' && orderId != null) {
        await _processMyFatoorahPayment(orderId, orderNumber);
      } else {
        // الدفع عند الاستلام - تحديث السلة والانتقال لصفحة النجاح
        context.read<CartProvider>().refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم إنشاء الطلب بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        if (orderNumber != null) {
          print('🔢 [Checkout] رقم الطلب: $orderNumber');
          context.push('/order-track/$orderNumber');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      print('❌ [Checkout] فشل إنشاء الطلب: $e');
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
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// معالجة الدفع عبر MyFatoorah
  Future<void> _processMyFatoorahPayment(int orderId, String? orderNumber) async {
    print('💳 [Checkout] بدء عملية الدفع عبر MyFatoorah للطلب: $orderId');

    final paymentProvider = context.read<PaymentProvider>();

    final state = await paymentProvider.executeMyFatoorahPayment(
      orderId: orderId,
      customerName: _name.text,
      customerEmail: _email.text,
      customerPhone: _phone.text,
    );

    if (!mounted) return;

    if (state.paymentUrl != null) {
      print('✅ [Checkout] تم الحصول على رابط الدفع');
      print('   URL: ${state.paymentUrl}');
      print('   Transaction ID: ${state.transactionId}');

      // الانتقال لصفحة WebView للدفع
      context.push(
        '/payment/webview'
        '?url=${Uri.encodeComponent(state.paymentUrl!)}'
        '&orderId=$orderId'
        '&tx=${state.transactionId ?? 0}',
      );
    } else if (state.errorMessage != null) {
      print('❌ [Checkout] فشل الدفع: ${state.errorMessage}');
      _showPaymentErrorDialog(state.errorMessage!, orderNumber);
    }
  }

  /// عرض dialog خطأ الدفع مع خيارات
  void _showPaymentErrorDialog(String message, String? orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ في الدفع'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'تم حفظ طلبك. يمكنك المحاولة مرة أخرى أو اختيار الدفع عند الاستلام.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // تغيير طريقة الدفع للدفع عند الاستلام
              this.context.read<PaymentProvider>().selectPaymentMethod('cash');
              setState(() => _paymentMethod = 'cash');
            },
            child: const Text('الدفع عند الاستلام'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // محاولة الدفع مرة أخرى
              if (orderNumber != null) {
                // TODO: إعادة محاولة الدفع
              }
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _selectAddress(AddressModel address) async {
    print('📍 [Checkout] تحديد العنوان: ${address.label}');
    setState(() {
      _selectedAddress = address;
      _selectedGovernorate = address.governorate;
      _selectedCity = address.city;
      _address.text = address.address;

      // فلترة أولية للقيم غير الصالحة
      if (_selectedCity == 'Voluptate velit exer.') {
        print('⚠️ [Checkout] تم العثور على قيمة مدينة غير صالحة، سيتم تجاهلها.');
        _selectedCity = null;
      }

      // التحقق من أن المحافظة المحددة موجودة في القائمة
      if (_selectedGovernorate != null && !_governorates.any((g) => g['name_ar'] == _selectedGovernorate)) {
        print('⚠️ [Checkout] المحافظة المحددة "$_selectedGovernorate" غير موجودة في القائمة، سيتم إعادة تعيينها');
        _selectedGovernorate = null;
        _selectedCity = null; // Reset city as well
      }
    });
    
    // جلب المدن للمحافظة المحددة
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart_checkout,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'إتمام الطلب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارِ تحميل البيانات...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // رسالة ترحيبية
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.primaryContainer.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_checkout,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'أوشكت على إتمام طلبك!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'املأ البيانات التالية لإكمال الطلب',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // معلومات العميل
                  _buildSectionHeader(
                    icon: Icons.person_outline,
                    title: 'معلومات العميل',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _name,
                    label: 'الاسم الكامل',
                    icon: Icons.person,
                    validator: (v) => v?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _email,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'الرجاء إدخال البريد الإلكتروني';
                      if (!v!.contains('@')) return 'البريد الإلكتروني غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _phone,
                    label: 'رقم الهاتف',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty ?? true ? 'الرجاء إدخال رقم الهاتف' : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // العناوين المحفوظة
                  if (_savedAddresses.isNotEmpty) ...[
                    _buildSectionHeader(
                      icon: Icons.location_on_outlined,
                      title: 'اختر عنواناً محفوظاً',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _savedAddresses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (_, i) {
                          final addr = _savedAddresses[i];
                          final isSelected = _selectedAddress?.id == addr.id;
                          
                          return InkWell(
                            onTap: () => _selectAddress(addr),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          addr.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (addr.isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'افتراضي',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    addr.address,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                  
                  // عنوان التوصيل
                  _buildSectionHeader(
                    icon: Icons.local_shipping_outlined,
                    title: 'عنوان التوصيل',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 20),
                  
                  // المحافظة (Dropdown)
                  DropdownButtonFormField<String>(
                    value: _selectedGovernorate,
                    dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'المحافظة',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      prefixIcon: Icon(
                        Icons.map,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                    ),
                    hint: const Text('اختر المحافظة'),
                    isExpanded: true,
                    items: _governorates.map((gov) {
                      return DropdownMenuItem<String>(
                        value: gov['name_ar'] as String?,
                        child: Text(gov['name_ar'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;

                      final selectedGov = _governorates.firstWhere(
                        (g) => g['name_ar'] == value,
                        orElse: () => <String, dynamic>{},
                      );

                      if (selectedGov.isNotEmpty) {
                        setState(() {
                          _selectedGovernorate = value;
                          _selectedGovernorateId = (selectedGov['id'] as num?)?.toInt();
                          _selectedCity = null; // Reset city
                          _cities = [];
                        });

                        if (_selectedGovernorateId != null) {
                          await _loadCities();
                        }
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'الرجاء اختيار المحافظة' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // المدينة (Dropdown)
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'المدينة',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      prefixIcon: Icon(
                        Icons.location_city,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                      suffixIcon: _isLoadingCities
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    hint: Text(
                      _selectedGovernorate == null
                          ? 'اختر المحافظة أولاً'
                          : 'اختر المدينة',
                    ),
                    isExpanded: true,
                    items: _cities.map((city) {
                      return DropdownMenuItem<String>(
                        value: city['name_ar'] as String?,
                        child: Text(city['name_ar'] as String? ?? ''),
                      );
                    }).toList(),
                    onChanged: _selectedGovernorate == null || _isLoadingCities
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCity = value;
                            });
                          },
                    validator: (v) => v == null || v.isEmpty ? 'الرجاء اختيار المدينة' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _address,
                    label: 'العنوان التفصيلي',
                    icon: Icons.home,
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'الرجاء إدخال العنوان' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _notes,
                    label: 'ملاحظات إضافية (اختياري)',
                    icon: Icons.note,
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // نوع التوصيل
                  _buildSectionHeader(
                    icon: Icons.delivery_dining,
                    title: 'نوع التوصيل',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _deliveryType = 'immediate'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _deliveryType == 'immediate'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.electric_bolt,
                                    color: _deliveryType == 'immediate'
                                        ? Colors.white
                                        : isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'توصيل فوري',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _deliveryType == 'immediate'
                                          ? Colors.white
                                          : isDark ? Colors.white : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'خلال ساعتين',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _deliveryType == 'immediate'
                                          ? Colors.white70
                                          : isDark ? Colors.grey[500] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _deliveryType = 'scheduled'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _deliveryType == 'scheduled'
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: _deliveryType == 'scheduled'
                                        ? Colors.white
                                        : isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'موعد محدد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _deliveryType == 'scheduled'
                                          ? Colors.white
                                          : isDark ? Colors.white : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'حدد الوقت',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _deliveryType == 'scheduled'
                                          ? Colors.white70
                                          : isDark ? Colors.grey[500] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // طريقة الدفع
                  _buildSectionHeader(
                    icon: Icons.payment,
                    title: 'طريقة الدفع',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  
                  PaymentMethodsWidget(
                    onMethodChanged: (method) {
                      setState(() => _paymentMethod = method);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ملخص الطلب
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.4),
                          colorScheme.primaryContainer.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'ملخص الطلب',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 18,
                                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'عدد المنتجات:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${cart.items.length} منتج',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'الإجمالي:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${cart.subtotal.toStringAsFixed(2)} د.ع',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // زر إتمام الطلب
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('جارٍ الإرسال...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline),
                                SizedBox(width: 12),
                                Text(
                                  'تأكيد الطلب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      // تحديد لون النص صراحةً لضمان الوضوح
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        // لون التسمية
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        // لون التسمية عند التركيز
        floatingLabelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        // لون الخلفية حسب الثيم
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
