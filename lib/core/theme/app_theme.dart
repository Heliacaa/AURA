import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Colors
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFA855F7);
  static const Color secondaryAccent = Color(0xFF00BFA5);
  static const Color warningOrange = Color(0xFFFF6B35);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textGray = Color(0xFF9CA3AF);
  static const Color chatUserBubble = Color(0xFF2A2A2A);
  static const Color statBlue = Color(0xFF3B82F6);
  static const Color statPink = Color(0xFFEC4899);
  static const Color statRed = Color(0xFFEF4444);

  // Dimensions
  static const double cardBorderRadius = 12.0;
  static const double cardLeftBorderWidth = 3.0;

  // Reusable card decoration
  static BoxDecoration cardDecoration({Color borderColor = primaryAccent}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      border: Border(
        left: BorderSide(color: borderColor, width: cardLeftBorderWidth),
      ),
    );
  }

  // Gradient button decoration
  static BoxDecoration gradientButton({double radius = 30}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF9B59B6), primaryAccent],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primaryAccent.withAlpha(80),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Input decoration
  static InputDecoration inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: textSecondary, size: 20)
          : null,
      filled: true,
      fillColor: cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        borderSide: const BorderSide(color: primaryAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        borderSide: const BorderSide(color: statRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        borderSide: const BorderSide(color: statRed, width: 1.5),
      ),
    );
  }

  // Text styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textWhite,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textWhite,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textWhite,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textWhite,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textWhite,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get labelBold => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textWhite,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: primaryAccent,
        secondary: secondaryAccent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textWhite,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF111111),
        selectedItemColor: primaryAccent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBackground,
        contentTextStyle: GoogleFonts.poppins(color: textWhite, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryAccent,
      ),
    );
  }
}
