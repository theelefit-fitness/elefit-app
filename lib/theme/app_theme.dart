import 'package:flutter/material.dart';

class AppTheme {
  // Primary brand colors - New Palette
  static const Color primaryColor = Color(0xFF4E3580); // Deep Purple - headers, app bar
  static const Color accentColor = Color(0xFFC8DA2B); // Lime Green - CTAs, accents, icons
  static const Color energyColor = Color(0xFFC8DA2B); // Lime Green - success, positive actions
  static const Color backgroundColor = Color(0xFFF8F8F8); // Light gray background
  static const Color surfaceColor = Color(0xFFFFFFFF); // White surface
  static const Color textColor = Color(0xFF4D4D4D); // Dark gray - primary text
  static const Color secondaryTextColor = Color(0xFF6B6B6B); // Medium gray - secondary text
  static const Color successColor = Color(0xFFC8DA2B); // Lime Green - success states
  static const Color saleColor = Color(0xFFC8DA2B); // Lime Green - highlights

  // Light theme colors
  static const Color lightPrimaryColor = Color(0xFF4E3580); // Deep Purple
  static const Color lightBackgroundColor = Color(0xFFF8F8F8); // Light gray
  static const Color lightSurfaceColor = Color(0xFFFFFFFF); // White
  static const Color lightTextColor = Color(0xFF4D4D4D); // Dark gray
  static const Color lightSecondaryTextColor = Color(0xFF6B6B6B); // Medium gray

  // Additional brand colors
  static const Color goldAccent = Color(0xFFC8DA2B); // Lime Green for highlights
  static const Color darkTeal = Color(0xFF4E3580); // Deep Purple alternative
  static const Color darkGrey = Color(0xFF4D4D4D); // Dark gray for cards/UI
  static const Color lightGrey = Color(0xFF6B6B6B); // Medium gray

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF3A2860)], // Deep Purple gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energyGradient = LinearGradient(
    colors: [accentColor, Color(0xFFD4E84F)], // Lime Green gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFFB8C625)], // Lime Green darker gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: accentColor, // Lime Green
      secondary: primaryColor, // Deep Purple
      error: Color(0xFFFF3D71), // Red for errors
      background: backgroundColor, // Light gray
      surface: surfaceColor, // White
      onPrimary: Color(0xFF000000), // Black text on lime green
      onSecondary: Color(0xFFFFFFFF), // White text on deep purple
      onSurface: textColor, // Dark gray text
      onBackground: textColor, // Dark gray text
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor, // Deep Purple
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)), // White icons
      titleTextStyle: TextStyle(
        color: Color(0xFFFFFFFF), // White text
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor, // Lime Green
        foregroundColor: const Color(0xFF000000), // Black text
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: const BorderSide(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textColor,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        color: textColor,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: textColor,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      headlineMedium: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 16,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: secondaryTextColor,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surfaceColor,
      shadowColor: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE8E8E8), // Light gray
      selectedColor: accentColor.withOpacity(0.2), // Lime Green tint
      labelStyle: const TextStyle(color: textColor), // Dark gray text
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F0), // Very light gray
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentColor, width: 2), // Lime Green
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF3D71)), // Red
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: secondaryTextColor),
      hintStyle: const TextStyle(color: secondaryTextColor),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor, // White
      selectedItemColor: accentColor, // Lime Green
      unselectedItemColor: secondaryTextColor, // Medium gray
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0), // Light gray divider
      thickness: 1,
      space: 32,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor.withOpacity(0.95),
      contentTextStyle: const TextStyle(color: textColor),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: secondaryTextColor,
        fontSize: 16,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      modalBackgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: lightPrimaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: accentColor,
      secondary: energyColor,
      error: energyColor,
      background: lightBackgroundColor,
      surface: lightSurfaceColor,
      onPrimary: lightTextColor,
      onSecondary: lightTextColor,
      onSurface: lightTextColor,
      onBackground: lightTextColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor, // Deep Purple
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)), // White icons
      titleTextStyle: TextStyle(
        color: Color(0xFFFFFFFF), // White text
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor, // Lime Green
        foregroundColor: const Color(0xFF000000), // Black text
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: const BorderSide(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: lightTextColor,
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        color: lightTextColor,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        color: lightTextColor,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: lightTextColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      headlineMedium: TextStyle(
        color: lightTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        color: lightTextColor,
        fontSize: 16,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: lightSecondaryTextColor,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: lightSurfaceColor,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE8E8E8), // Light gray
      selectedColor: accentColor.withOpacity(0.2), // Lime Green tint
      labelStyle: const TextStyle(color: lightTextColor), // Dark gray text
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F0), // Very light gray
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentColor, width: 2), // Lime Green
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF3D71)), // Red
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: lightSecondaryTextColor),
      hintStyle: const TextStyle(color: lightSecondaryTextColor),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurfaceColor,
      selectedItemColor: accentColor,
      unselectedItemColor: lightSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0), // Light gray divider
      thickness: 1,
      space: 32,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightSurfaceColor.withOpacity(0.95),
      contentTextStyle: TextStyle(color: lightTextColor),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: TextStyle(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: lightSecondaryTextColor,
        fontSize: 16,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightSurfaceColor,
      modalBackgroundColor: lightSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    ),
  );
} 