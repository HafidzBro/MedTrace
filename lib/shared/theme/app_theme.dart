import 'package:flutter/material.dart';

class AppColors {
  // Patient Theme Colors
  static const Color patientPrimary = Color(0xFF0F766E); // Teal
  static const Color patientSecondary = Color(0xFF14B8A6);
  static const Color patientBackground = Color(0xFFF0FDFA);
  static const Color patientAccent = Color(0xFFEAB308);

  // Doctor Theme Colors
  static const Color doctorPrimary = Color(0xFF134E4A); // Darker teal
  static const Color doctorSecondary = Color(0xFF0F766E);
  static const Color doctorBackground = Color(0xFFECFEFF);

  // Semantic Colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningYellow = Color(0xFFFBBF24);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Backward-compatible semantic aliases used by feature screens.
  static const Color patient = patientPrimary;
  static const Color doctor = doctorPrimary;
  static const Color success = successGreen;
  static const Color warning = warningYellow;
  static const Color error = errorRed;
  static const Color info = infoBlue;

  // Neutral Colors
  static const Color darkGrey = Color(0xFF1F2937);
  static const Color mediumGrey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color veryLightGrey = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color text = darkGrey;
  static const Color textSecondary = mediumGrey;
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
}

class AppTypography {
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    letterSpacing: -0.5,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
  );

  static const TextStyle headlineSmall = headline4;
  static const TextStyle headlineMedium = headline3;

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
    height: 1.33,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    letterSpacing: 0.4,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
    color: AppColors.mediumGrey,
  );
}

class AppTheme {
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  AppTheme({required this.lightTheme, required this.darkTheme});

  factory AppTheme.patient() {
    return AppTheme(
      lightTheme: _buildPatientTheme(),
      darkTheme: _buildPatientDarkTheme(),
    );
  }

  factory AppTheme.doctor() {
    return AppTheme(
      lightTheme: _buildDoctorTheme(),
      darkTheme: _buildDoctorDarkTheme(),
    );
  }

  static ThemeData _buildPatientTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.patientPrimary,
        secondary: AppColors.patientSecondary,
        surface: AppColors.white,
        background: AppColors.patientBackground,
        error: AppColors.errorRed,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkGrey,
        onBackground: AppColors.darkGrey,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.patientBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGrey,
        titleTextStyle: AppTypography.headline4.copyWith(
          color: AppColors.darkGrey,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.mediumGrey,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.patientPrimary,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.patientPrimary,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.patientPrimary,
          side: const BorderSide(color: AppColors.patientPrimary),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.headline1.copyWith(
          color: AppColors.darkGrey,
        ),
        displayMedium: AppTypography.headline2.copyWith(
          color: AppColors.darkGrey,
        ),
        displaySmall: AppTypography.headline3.copyWith(
          color: AppColors.darkGrey,
        ),
        headlineMedium: AppTypography.headline4.copyWith(
          color: AppColors.darkGrey,
        ),
        headlineSmall: AppTypography.headline4.copyWith(
          color: AppColors.darkGrey,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkGrey),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkGrey,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.mediumGrey,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkGrey,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.darkGrey,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.mediumGrey,
        ),
      ),
    );
  }

  static ThemeData _buildPatientDarkTheme() {
    return _buildPatientTheme();
  }

  static ThemeData _buildDoctorTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.doctorPrimary,
        secondary: AppColors.doctorSecondary,
        surface: AppColors.white,
        background: AppColors.doctorBackground,
        error: AppColors.errorRed,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkGrey,
        onBackground: AppColors.darkGrey,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.doctorBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGrey,
        titleTextStyle: AppTypography.headline4.copyWith(
          color: AppColors.darkGrey,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.headline1.copyWith(
          color: AppColors.darkGrey,
        ),
        displayMedium: AppTypography.headline2.copyWith(
          color: AppColors.darkGrey,
        ),
        displaySmall: AppTypography.headline3.copyWith(
          color: AppColors.darkGrey,
        ),
        headlineMedium: AppTypography.headline4.copyWith(
          color: AppColors.darkGrey,
        ),
        headlineSmall: AppTypography.headline4.copyWith(
          color: AppColors.darkGrey,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkGrey),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkGrey,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.mediumGrey,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkGrey,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.darkGrey,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.mediumGrey,
        ),
      ),
    );
  }

  static ThemeData _buildDoctorDarkTheme() {
    return _buildDoctorTheme();
  }
}
