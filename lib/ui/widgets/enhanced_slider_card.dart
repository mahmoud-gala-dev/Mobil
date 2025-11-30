import 'package:flutter/material.dart';
import '../../models/models.dart';

class EnhancedSliderCard extends StatelessWidget {
  final SliderModel slider;

  const EnhancedSliderCard({super.key, required this.slider});

  void _launchUrl(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    
    // يمكن إضافة url_launcher لاحقاً، حالياً عرض رسالة فقط
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('الرابط: $url'),
        action: SnackBarAction(
          label: 'حسناً',
          onPressed: () {},
        ),
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    
    try {
      // Remove # if present
      colorString = colorString.replaceAll('#', '');
      
      // If it's a 6-digit hex, add FF for full opacity
      if (colorString.length == 6) {
        colorString = 'FF$colorString';
      }
      
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [SliderCard] عرض السلايدر: ${slider.title}');
    print('🖼️  [SliderCard] مسار الصورة: ${slider.image}');
    print('📸 [SliderCard] مسار الخلفية: ${slider.backgroundImage}');
    
    final gradientColor = _parseColor(slider.gradientColor);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // حساب الارتفاع المناسب بناءً على حجم الشاشة
    final double cardHeight = screenHeight * 0.25; // 25% من ارتفاع الشاشة
    
    // أحجام نسبية بناءً على حجم الشاشة
    final double titleSize = screenWidth * 0.055; // 5.5% من عرض الشاشة
    final double subtitleSize = screenWidth * 0.04; // 4% من عرض الشاشة
    final double descriptionSize = screenWidth * 0.032; // 3.2% من عرض الشاشة
    final double badgeSize = screenWidth * 0.03; // 3% من عرض الشاشة
    final double buttonTextSize = screenWidth * 0.035; // 3.5% من عرض الشاشة
    final double padding = screenWidth * 0.04; // 4% من عرض الشاشة

    return Container(
      height: cardHeight,
      width: screenWidth,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (slider.backgroundImage != null && slider.backgroundImage!.isNotEmpty)
              Image.network(
                slider.backgroundImage!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              )
            else if (slider.image != null && slider.image!.isNotEmpty)
              Image.network(
                slider.image!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColor ?? Theme.of(context).colorScheme.primary,
                      (gradientColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.7),
                    ],
                  ),
                ),
              ),

            // Gradient Overlay
            if (gradientColor != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      gradientColor.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  if (slider.badge != null && slider.badge!.isNotEmpty)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.6,
                          vertical: padding * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          slider.badge!,
                          style: TextStyle(
                            fontSize: badgeSize,
                            fontWeight: FontWeight.bold,
                            color: gradientColor ?? Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Title, Subtitle, Description, Button
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          if (slider.title != null && slider.title!.isNotEmpty)
                            Text(
                              slider.title!,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          // Subtitle
                          if (slider.subtitle != null && slider.subtitle!.isNotEmpty) ...[
                            SizedBox(height: padding * 0.3),
                            Text(
                              slider.subtitle!,
                              style: TextStyle(
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Description
                          if (slider.description != null && slider.description!.isNotEmpty) ...[
                            SizedBox(height: padding * 0.2),
                            Text(
                              slider.description!,
                              style: TextStyle(
                                fontSize: descriptionSize,
                                color: Colors.white.withOpacity(0.95),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Button
                          if (slider.buttonText != null && slider.buttonText!.isNotEmpty) ...[
                            SizedBox(height: padding * 0.5),
                            ElevatedButton(
                              onPressed: () => _launchUrl(context, slider.buttonUrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: gradientColor ?? Theme.of(context).colorScheme.primary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 1.2,
                                  vertical: padding * 0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slider.buttonText!,
                                    style: TextStyle(
                                      fontSize: buttonTextSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: padding * 0.3),
                                  Icon(
                                    Icons.arrow_back,
                                    size: buttonTextSize * 1.2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

