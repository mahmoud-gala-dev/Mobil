import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import '../models/models.dart';

enum UserType { customer, vendor }

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  UserType? _userType;
  bool _isLoading = false;
  bool _isDeletingAccount = false;

  UserModel? get user => _user;
  String? get token => _token;
  UserType? get userType => _userType;
  bool get isLoading => _isLoading;
  bool get isDeletingAccount => _isDeletingAccount;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isVendor => _userType == UserType.vendor;
  bool get isCustomer => _userType == UserType.customer;

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      // التأكد من تهيئة الخدمة
      await SharedPreferencesService.instance.init();

      _token = SharedPreferencesService.instance.getString('auth_token');
      final userTypeStr =
          SharedPreferencesService.instance.getString('user_type');

      if (userTypeStr != null) {
        _userType =
            userTypeStr == 'vendor' ? UserType.vendor : UserType.customer;
      }

      if (_token != null) {
        try {
          await _loadUserProfile();
        } catch (e) {
          if (kDebugMode)
            print('⚠️ [AuthProvider] خطأ في تحميل الملف الشخصي: $e');
          await logout();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthProvider] خطأ في تحميل البيانات من التخزين: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiService.I.getUserProfile();
      // الاستجابة تحتوي على {'user': {...}}
      final userData = response['user'] as Map<String, dynamic>?;
      if (userData != null) {
        _user = UserModel.fromApi(userData);
        notifyListeners();
      } else {
        throw Exception('لا توجد بيانات مستخدم في الاستجابة');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginCustomer({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.I.loginCustomer(
        email: email,
        password: password,
      );

      // التحقق من وجود البيانات المطلوبة
      if (response['token'] == null) {
        throw Exception('لم يتم استلام التوكن من الخادم');
      }

      if (response['user'] == null) {
        throw Exception('لم يتم استلام بيانات المستخدم من الخادم');
      }

      _token = response['token'] as String;
      _userType = UserType.customer;
      _user = UserModel.fromApi(response['user'] as Map<String, dynamic>);

      await SharedPreferencesService.instance.setString('auth_token', _token!);
      await SharedPreferencesService.instance
          .setString('user_type', 'customer');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loginVendor({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📡 [AuthProvider] إرسال طلب تسجيل الدخول للبائع...');

      final response = await ApiService.I.loginVendor(
        email: email,
        password: password,
      );

      print('📦 [AuthProvider] استلام الاستجابة: ${response.keys}');

      // التحقق من وجود البيانات المطلوبة
      if (response['token'] == null) {
        print('❌ [AuthProvider] التوكن مفقود في الاستجابة');
        throw Exception('لم يتم استلام التوكن من الخادم');
      }

      if (response['user'] == null) {
        print('❌ [AuthProvider] بيانات المستخدم مفقودة في الاستجابة');
        throw Exception('لم يتم استلام بيانات المستخدم من الخادم');
      }

      _token = response['token'] as String;
      _userType = UserType.vendor;
      _user = UserModel.fromApi(response['user'] as Map<String, dynamic>);

      if (kDebugMode) {
        print('✅ [AuthProvider] تم حفظ البيانات في الذاكرة');
        print('   التوكن: ${_token!.substring(0, 20)}...');
        print('   المستخدم: ${_user?.name}');
        print('   النوع: vendor');
      }

      await SharedPreferencesService.instance.setString('auth_token', _token!);
      await SharedPreferencesService.instance.setString('user_type', 'vendor');

      if (kDebugMode) {
        print('✅ [AuthProvider] تم حفظ البيانات في SharedPreferences');
      }

      _isLoading = false;
      notifyListeners();

      print('✅ [AuthProvider] اكتمل تسجيل الدخول بنجاح');
    } catch (e, stackTrace) {
      print('❌ [AuthProvider] خطأ في loginVendor: $e');
      print('Stack trace: $stackTrace');

      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.I.registerCustomer(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      // التحقق من وجود البيانات المطلوبة
      if (response['token'] == null) {
        throw Exception('لم يتم استلام التوكن من الخادم');
      }

      if (response['user'] == null) {
        throw Exception('لم يتم استلام بيانات المستخدم من الخادم');
      }

      _token = response['token'] as String;
      _userType = UserType.customer;
      _user = UserModel.fromApi(response['user'] as Map<String, dynamic>);

      await SharedPreferencesService.instance.setString('auth_token', _token!);
      await SharedPreferencesService.instance
          .setString('user_type', 'customer');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerVendor({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String storeName,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.I.registerVendor(
        name: name,
        email: email,
        password: password,
        phone: phone,
        storeName: storeName,
        description: description,
      );

      // التحقق من وجود البيانات المطلوبة
      if (response['token'] == null) {
        throw Exception('لم يتم استلام التوكن من الخادم');
      }

      if (response['user'] == null) {
        throw Exception('لم يتم استلام بيانات المستخدم من الخادم');
      }

      _token = response['token'] as String;
      _userType = UserType.vendor;
      _user = UserModel.fromApi(response['user'] as Map<String, dynamic>);

      await SharedPreferencesService.instance.setString('auth_token', _token!);
      await SharedPreferencesService.instance.setString('user_type', 'vendor');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await ApiService.I.logout();
      }
    } catch (e) {
      if (kDebugMode) print('خطأ في تسجيل الخروج من API: $e');
    }

    _user = null;
    _token = null;
    _userType = null;

    await SharedPreferencesService.instance.remove('auth_token');
    await SharedPreferencesService.instance.remove('user_type');

    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      await ApiService.I.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );

      // إعادة تحميل الملف الشخصي بعد التحديث
      await _loadUserProfile();

      if (kDebugMode) {
        print('✅ [AuthProvider] تم تحديث الملف الشخصي بنجاح');
        print('   الاسم: ${_user?.name}');
        print('   البريد: ${_user?.email}');
        print('   الهاتف: ${_user?.phone}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [AuthProvider] خطأ في تحديث الملف الشخصي: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount({required String password}) async {
    _isDeletingAccount = true;
    notifyListeners();

    try {
      if (_userType == UserType.vendor) {
        await ApiService.I.deleteVendorAccount(password: password);
      } else {
        await ApiService.I.deleteAccount(password: password);
      }

      _user = null;
      _token = null;
      _userType = null;

      await SharedPreferencesService.instance.remove('auth_token');
      await SharedPreferencesService.instance.remove('user_type');

      if (kDebugMode) {
        print('✅ [AuthProvider] تم حذف الحساب ومسح بيانات الجلسة محلياً');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [AuthProvider] فشل حذف الحساب: $e');
      rethrow;
    } finally {
      _isDeletingAccount = false;
      notifyListeners();
    }
  }
}
