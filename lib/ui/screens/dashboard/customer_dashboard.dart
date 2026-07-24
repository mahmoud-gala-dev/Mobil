import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/app_drawer.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!auth.isAuthenticated || !auth.isCustomer) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'حسابي'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined,
                  size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'يجب تسجيل الدخول أولاً',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/auth/customer/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.user!;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'حسابي',
        leadingIcon: Icons.account_circle_rounded,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 45,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (user.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.phone!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Menu Items
            const Text(
              'الحساب والإعدادات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'طلباتي',
              subtitle: 'عرض وتتبع طلباتك',
              onTap: () => context.push('/orders'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.favorite_border,
              title: 'المفضلة',
              subtitle: 'المنتجات المفضلة لديك',
              onTap: () => context.push('/favorites'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: 'العناوين',
              subtitle: 'إدارة عناوين التوصيل',
              onTap: () => context.push('/addresses'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.edit_outlined,
              title: 'تعديل الملف الشخصي',
              subtitle: 'تحديث معلوماتك',
              onTap: () => context.push('/profile'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.lock_outline,
              title: 'تغيير كلمة المرور',
              subtitle: 'تحديث كلمة المرور',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريباً...')),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              subtitle: 'الخروج من الحساب',
              onTap: () => _showLogoutDialog(context),
              textColor: Colors.red,
            ),
            _buildMenuItem(
              context,
              icon: Icons.delete_forever_outlined,
              title: 'حذف الحساب',
              subtitle: 'حذف حسابك وبياناتك نهائياً',
              onTap: () => _showDeleteAccountDialog(context),
              textColor: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon,
            color: textColor ?? Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
                );
              }
            },
            child:
                const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final authProvider = context.read<AuthProvider>();
    var isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('حذف الحساب نهائياً'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'سيتم حذف الحساب والبيانات المرتبطة به نهائياً. أدخل كلمة المرور للتأكيد.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isDeleting) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى إدخال كلمة المرور'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isDeleting = true);

                          try {
                            await authProvider.deleteAccount(
                                password: password);

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              context.go('/auth/customer/login');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذف الحساب بنجاح'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل حذف الحساب: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('حذف الحساب'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(passwordController.dispose);
  }
}
