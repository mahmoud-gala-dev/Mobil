import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Drawer(
      child: Column(
        children: [
          // Header مع تصميم جذاب
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.store,
                    size: 50,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'إيليت وان',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elite One',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // القائمة الرئيسية
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                ),
                _DrawerItem(
                  icon: Icons.category_rounded,
                  title: 'الأقسام',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/categories');
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_offer_rounded,
                  title: 'العروض الخاصة',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/offers');
                  },
                ),
                _DrawerItem(
                  icon: Icons.store_rounded,
                  title: 'المتاجر',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/vendors');
                  },
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.shopping_cart_rounded,
                  title: 'السلة',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/cart');
                  },
                ),
                _DrawerItem(
                  icon: Icons.favorite_rounded,
                  title: 'المفضلة',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/favorites');
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'طلباتي',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/orders');
                  },
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.search_rounded,
                  title: 'البحث',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/search');
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  title: 'حسابي',
                  onTap: () {
                    Navigator.pop(context);
                    final auth = context.read<AuthProvider>();
                    if (auth.isAuthenticated) {
                      if (auth.isCustomer) {
                        context.push('/customer/dashboard');
                      } else if (auth.isVendor) {
                        context.push('/vendor/dashboard');
                      }
                    } else {
                      context.push('/auth/customer/login');
                    }
                  },
                ),
                
                // Theme toggle
                const Divider(height: 1),
                _ThemeToggleItem(),
                
                // Show auth-specific items based on login status
                Builder(
                  builder: (context) {
                    final auth = context.watch<AuthProvider>();
                    
                    if (!auth.isAuthenticated) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 1),
                          _DrawerItem(
                            icon: Icons.login_rounded,
                            title: 'تسجيل الدخول',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/auth/customer/login');
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.store_mall_directory_rounded,
                            title: 'تسجيل دخول البائع',
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/auth/vendor/login');
                            },
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 1),
                          if (auth.isVendor)
                            _DrawerItem(
                              icon: Icons.dashboard_rounded,
                              title: 'لوحة التحكم',
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/vendor/dashboard');
                              },
                            ),
                          _DrawerItem(
                            icon: Icons.logout_rounded,
                            title: 'تسجيل الخروج',
                            onTap: () async {
                              Navigator.pop(context);
                              await auth.logout();
                              if (context.mounted) {
                                context.go('/home');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'خدمة العملاء: 1234-567-890',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// عنصر تبديل الثيم (الوضع المضيء/المظلم)
class _ThemeToggleItem extends StatelessWidget {
  const _ThemeToggleItem();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(
        themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        size: 24,
      ),
      title: const Text(
        'الوضع المظلم',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
        activeColor: colorScheme.primary,
      ),
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

