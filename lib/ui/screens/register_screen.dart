import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  bool loading = false;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => loading = true);
    try {
      await ApiService.I.register(_name.text, _email.text, _password.text, phone: _phone.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إنشاء الحساب')));
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'الهاتف')),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: loading ? null : _submit, child: Text(loading ? 'جارٍ الإنشاء...' : 'إنشاء'))),
        ]),
      ),
    );
  }
}
