import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============ ألوان التطبيق الرئيسية ============
  
  // اللون الأساسي - الأخضر (مطابق للموقع)
  static const Color primaryColor = Color(0xFF16A34A); // green-600
  static const Color primaryLightColor = Color(0xFF22C55E); // green-500
  static const Color primaryDarkColor = Color(0xFF15803D); // green-700
  
  // الألوان الثانوية
  static const Color secondaryColor = Color(0xFF0EA5E9); // sky-500
  static const Color accentColor = Color(0xFFF59E0B); // amber-500
  
  // ألوان الحالة
  static const Color successColor = Color(0xFF10B981); // emerald-500
  static const Color errorColor = Color(0xFFEF4444); // red-500
  static const Color warningColor = Color(0xFFF59E0B); // amber-500
  static const Color infoColor = Color(0xFF3B82F6); // blue-500
  
  // الألوان المحايدة
  static const Color backgroundColor = Color(0xFFF9FAFB); // gray-50
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // ألوان النص
  static const Color textPrimaryColor = Color(0xFF111827); // gray-900
  static const Color textSecondaryColor = Color(0xFF6B7280); // gray-500
  static const Color textDisabledColor = Color(0xFF9CA3AF); // gray-400
  
  // ============ الثيم الفاتح ============
  
  static ThemeData lightTheme() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );
    
    return baseTheme.copyWith(
      // نظام الألوان
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        brightness: Brightness.light,
      ),
      
      // الخطوط
      textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textDisabledColor,
          height: 1.4,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        iconTheme: const IconThemeData(
          color: textPrimaryColor,
          size: 24,
        ),
      ),
      
      // Card
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: EdgeInsets.zero,
      ),
      
      // الأزرار المرتفعة
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // الأزرار المحددة
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // الأزرار النصية
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        hintStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: textDisabledColor,
        ),
      ),
      
      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        height: 65,
        elevation: 8,
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: primaryColor,
              size: 24,
            );
          }
          return const IconThemeData(
            color: textSecondaryColor,
            size: 24,
          );
        }),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        deleteIconColor: textSecondaryColor,
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: surfaceColor,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 15,
          color: textPrimaryColor,
          height: 1.5,
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 1,
      ),
      
      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 16,
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // IconButton
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimaryColor,
          padding: const EdgeInsets.all(8),
        ),
      ),
      
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: textSecondaryColor,
        ),
        iconColor: textSecondaryColor,
      ),
      
      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE5E7EB),
        circularTrackColor: Color(0xFFE5E7EB),
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey[300];
        }),
      ),
      
      // TabBar
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 3),
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: backgroundColor,
    );
  }
  
  // ============ الثيم المظلم ============
  
  static ThemeData darkTheme() {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    
    return baseTheme.copyWith(
      // نظام الألوان
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: const Color(0xFF1E1E1E),
        brightness: Brightness.dark,
      ),
      
      // الخطوط
      textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white60,
          height: 1.4,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      
      // Card
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF1E1E1E),
        shadowColor: Colors.black.withOpacity(0.3),
        margin: EdgeInsets.zero,
      ),
      
      // الأزرار المرتفعة
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // الأزرار المحددة
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // الأزرار النصية
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.white70,
        ),
        hintStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      
      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        height: 65,
        elevation: 8,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: primaryColor.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: primaryColor,
              size: 24,
            );
          }
          return const IconThemeData(
            color: Colors.white70,
            size: 24,
          );
        }),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        deleteIconColor: Colors.white70,
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 15,
          color: Colors.white,
          height: 1.5,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3C3C3C),
        thickness: 1,
        space: 1,
      ),
      
      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 16,
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // IconButton
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
        ),
      ),
      
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: Colors.white70,
        ),
        iconColor: Colors.white70,
      ),
      
      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFF3C3C3C),
        circularTrackColor: Color(0xFF3C3C3C),
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey[700];
        }),
      ),
      
      // TabBar
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.white70,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 3),
        ),
        labelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }
  
  // ============ دوال مساعدة للألوان ============
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warningColor;
      case 'processing':
        return infoColor;
      case 'completed':
      case 'delivered':
        return successColor;
      case 'cancelled':
      case 'rejected':
        return errorColor;
      default:
        return textSecondaryColor;
    }
  }
  
  static Color getRatingColor(double rating) {
    if (rating >= 4.5) return successColor;
    if (rating >= 3.5) return primaryColor;
    if (rating >= 2.5) return warningColor;
    return errorColor;
  }
}

