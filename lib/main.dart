import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/progress_provider.dart';
import 'screens/emotion_recognition/emotion_recognition_screen.dart';
import 'screens/expression_mirroring/expression_mirroring_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/parent_mode/parent_dashboard_screen.dart';
import 'screens/parent_mode/pin_entry_screen.dart';
import 'screens/profile/profile_select_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/social_situations/social_situations_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final audioService = AudioService();
  await audioService.init();

  final progressProvider = ProgressProvider(storageService);
  await progressProvider.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AudioService>.value(value: audioService),
        ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
      ],
      child: const MoodmatesApp(),
    ),
  );
}

GoRouter _buildRouter(ProgressProvider progressProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: progressProvider,
    redirect: (context, state) {
      final hasProfiles = progressProvider.hasAnyProfile;
      final hasActiveProfile = progressProvider.hasActiveProfile &&
          progressProvider.progress.childName.isNotEmpty;
      final isHome = state.matchedLocation == '/home';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isProfiles = state.matchedLocation == '/profiles';

      if (!hasProfiles && !isOnboarding) return '/onboarding';
      if (hasProfiles && !hasActiveProfile && !isProfiles) return '/profiles';
      if (hasProfiles && isOnboarding) {
        return hasActiveProfile ? '/home' : '/profiles';
      }
      if (hasProfiles && state.matchedLocation == '/') return '/profiles';
      if (!hasProfiles && isHome) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profiles',
        builder: (_, __) => const ProfileSelectScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const ProfileSelectScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/emotion-recognition',
        builder: (_, __) => const EmotionRecognitionScreen(),
      ),
      GoRoute(
        path: '/expression-mirroring',
        builder: (_, __) => const ExpressionMirroringScreen(),
      ),
      GoRoute(
        path: '/social-situations',
        builder: (_, __) => const SocialSituationsScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (_, __) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/parent-pin',
        builder: (_, __) => const PinEntryScreen(),
      ),
      GoRoute(
        path: '/parent-dashboard',
        builder: (_, __) => const ParentDashboardScreen(),
      ),
    ],
  );
}

class MoodmatesApp extends StatefulWidget {
  const MoodmatesApp({super.key});

  @override
  State<MoodmatesApp> createState() => _MoodmatesAppState();
}

class _MoodmatesAppState extends State<MoodmatesApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    final progressProvider = context.read<ProgressProvider>();
    _router = _buildRouter(progressProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moodmates',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9A3C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.baloo2(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3D2B1A),
            height: 1.1,
          ),
          displayMedium: GoogleFonts.baloo2(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3D2B1A),
            height: 1.15,
          ),
          titleLarge: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2B1A),
            height: 1.15,
          ),
          titleMedium: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2B1A),
          ),
          bodyLarge: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D2B1A),
          ),
          bodyMedium: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D2B1A),
          ),
          bodySmall: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8D6E63),
          ),
          labelLarge: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2B1A),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFF9A3C),
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: GoogleFonts.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF8E7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
