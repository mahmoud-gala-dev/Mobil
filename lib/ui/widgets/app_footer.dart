import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';

/// Footer قوي وجذاب للتطبيق
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
            ? [
                colorScheme.surface,
                colorScheme.surfaceVariant,
              ]
            : [
                colorScheme.primary.withOpacity(0.05),
                colorScheme.primary.withOpacity(0.1),
              ],
        ),
      ),
      child: Column(
        children: [
          // القسم الرئيسي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الشعار والوصف
                _buildBrandSection(context),
                
                const SizedBox(height: 32),
                
                // الروابط السريعة في 3 أعمدة
                LayoutBuilder(
                  builder: (context, constraints) {
                    // إذا كانت الشاشة صغيرة، نستخدم عمود واحد
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickLinksSection(context),
                          const SizedBox(height: 24),
                          _buildStaticPagesSection(context),
                          const SizedBox(height: 24),
                          _buildContactSection(context),
                        ],
                      );
                    }
                    
                    // إذا كانت الشاشة كبيرة، نستخدم 3 أعمدة
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildQuickLinksSection(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStaticPagesSection(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildContactSection(context)),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // السوشيال ميديا
                _buildSocialMedia(context),
                
                const SizedBox(height: 24),
                
                // معلومات التطبيق
                _buildAppInfo(context),
              ],
            ),
          ),
          
          // شريط الحقوق
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: _buildCopyright(context),
          ),
        ],
      ),
    );
  }
  
  // قسم الشعار والوصف
  Widget _buildBrandSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الشعار
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Engeb',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // الوصف
        Text(
          'منصة تسوق إلكترونية متكاملة تقدم لك أفضل المنتجات بأسعار منافسة وجودة عالية. تسوق الآن واستمتع بتجربة شراء مميزة.',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  // الروابط السريعة
  Widget _buildQuickLinksSection(BuildContext context) {
    return _buildFooterSection(
      context,
      title: 'روابط سريعة',
      icon: Icons.link_rounded,
      items: [
        _FooterLink(
          title: 'الرئيسية',
          icon: Icons.home_outlined,
          onTap: () => context.go('/home'),
        ),
        _FooterLink(
          title: 'جميع الأقسام',
          icon: Icons.category_outlined,
          onTap: () => context.push('/categories'),
        ),
        _FooterLink(
          title: 'العروض الخاصة',
          icon: Icons.local_offer_outlined,
          onTap: () => context.push('/offers'),
        ),
        _FooterLink(
          title: 'المتاجر',
          icon: Icons.store_outlined,
          onTap: () => context.push('/vendors'),
        ),
        _FooterLink(
          title: 'المفضلة',
          icon: Icons.favorite_border,
          onTap: () => context.push('/favorites'),
        ),
        _FooterLink(
          title: 'السلة',
          icon: Icons.shopping_cart_outlined,
          onTap: () => context.push('/cart'),
        ),
      ],
    );
  }
  
  // الصفحات الثابتة
  Widget _buildStaticPagesSection(BuildContext context) {
    return _buildFooterSection(
      context,
      title: 'معلومات',
      icon: Icons.info_outline,
      items: [
        _FooterLink(
          title: 'من نحن',
          icon: Icons.business_outlined,
          onTap: () => context.push('/about-us'),
        ),
        _FooterLink(
          title: 'سياسة الخصوصية',
          icon: Icons.privacy_tip_outlined,
          onTap: () => context.push('/privacy-policy'),
        ),
        _FooterLink(
          title: 'الشروط والأحكام',
          icon: Icons.description_outlined,
          onTap: () => context.push('/terms-conditions'),
        ),
        _FooterLink(
          title: 'سياسة الاسترجاع',
          icon: Icons.assignment_return_outlined,
          onTap: () => context.push('/return-policy'),
        ),
        _FooterLink(
          title: 'الأسئلة الشائعة',
          icon: Icons.help_outline,
          onTap: () => context.push('/faq'),
        ),
      ],
    );
  }
  
  // قسم التواصل
  Widget _buildContactSection(BuildContext context) {
    return _buildFooterSection(
      context,
      title: 'تواصل معنا',
      icon: Icons.contact_phone_outlined,
      items: [
        _FooterLink(
          title: 'الدعم الفني',
          icon: Icons.support_agent_outlined,
          subtitle: 'متاح 24/7',
          onTap: () {
            // TODO: إضافة صفحة الدعم الفني
            _showComingSoon(context, 'الدعم الفني');
          },
        ),
        _FooterLink(
          title: 'البريد الإلكتروني',
          icon: Icons.email_outlined,
          subtitle: 'info@engeb.com',
          onTap: () {},
        ),
        _FooterLink(
          title: 'الهاتف',
          icon: Icons.phone_outlined,
          subtitle: '+20 123 456 7890',
          onTap: () {},
        ),
        _FooterLink(
          title: 'العنوان',
          icon: Icons.location_on_outlined,
          subtitle: 'القاهرة، مصر',
          onTap: () {},
        ),
      ],
    );
  }
  
  // السوشيال ميديا
  Widget _buildSocialMedia(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تابعنا على',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSocialButton(
              context,
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onTap: () {},
            ),
            _buildSocialButton(
              context,
              icon: Icons.language,
              label: 'Twitter',
              color: const Color(0xFF1DA1F2),
              onTap: () {},
            ),
            _buildSocialButton(
              context,
              icon: Icons.photo_camera,
              label: 'Instagram',
              color: const Color(0xFFE4405F),
              onTap: () {},
            ),
            _buildSocialButton(
              context,
              icon: Icons.play_circle_outline,
              label: 'YouTube',
              color: const Color(0xFFFF0000),
              onTap: () {},
            ),
            _buildSocialButton(
              context,
              icon: Icons.telegram,
              label: 'Telegram',
              color: const Color(0xFF0088CC),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
  
  // معلومات التطبيق
  Widget _buildAppInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
           
                const SizedBox(height: 4),
                Text(
                  ApiConfig.environmentInfo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // الحقوق
  Widget _buildCopyright(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '© ${DateTime.now().year} Engeb. جميع الحقوق محفوظة.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),

      ],
    );
  }
  
  // قسم Footer
  Widget _buildFooterSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_FooterLink> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildFooterLinkItem(context, item)),
      ],
    );
  }
  
  // عنصر رابط Footer
  Widget _buildFooterLinkItem(BuildContext context, _FooterLink link) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: link.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                link.icon,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (link.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        link.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios,
                size: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // زر السوشيال ميديا
  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // رسالة قريباً
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('صفحة "$feature" قريباً'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// نموذج رابط Footer
class _FooterLink {
  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback onTap;

  const _FooterLink({
    required this.title,
    required this.icon,
    this.subtitle,
    required this.onTap,
  });
}

