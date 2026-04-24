import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/deck.dart';
import 'models/flashcard.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  Hive.registerAdapter(DeckAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  await Hive.openBox<Deck>('decks');
  await Hive.openBox<Flashcard>('cards');
  await NotificationService.init();
  await NotificationService.scheduleDailyReminder();
  await Supabase.initialize(
    url: '',
    anonKey:'',
  );

  runApp(const SmartStudyApp());
}

// ─── App Color Palette ────────────────────────────────────────────────────────
class AppColors {
  // Deep midnight navy
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const card = Color(0xFF1C2333);
  static const cardBorder = Color(0xFF30363D);

  // Warm amber accent
  static const accent = Color(0xFFFFB347);
  static const accentDark = Color(0xFFE8961A);
  static const accentGlow = Color(0x33FFB347);

  // Semantic colours
  static const success = Color(0xFF3FB950);
  static const danger = Color(0xFFF85149);
  static const warning = Color(0xFFD29922);
  static const info = Color(0xFF58A6FF);

  // Text
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
}

class SmartStudyApp extends StatefulWidget {
  const SmartStudyApp({super.key});

  @override
  State<SmartStudyApp> createState() => _SmartStudyAppState();
}

class _SmartStudyAppState extends State<SmartStudyApp> {
  void toggleTheme() {} // reserved, currently single dark theme

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.spaceGroteskTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.info,
          surface: AppColors.surface,
          error: AppColors.danger,
          onPrimary: AppColors.bg,
          onSecondary: AppColors.bg,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: base.copyWith(
          displayLarge: base.displayLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textPrimary),
          bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: AppColors.textSecondary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.bg,
          elevation: 4,
        ),
        dividerColor: AppColors.cardBorder,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      home: AuthGate(onToggleTheme: toggleTheme),
    );
  }
}
