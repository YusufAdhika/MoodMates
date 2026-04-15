import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/progress_provider.dart';
import 'screens/emotion_recognition/emotion_recognition_screen.dart';
import 'screens/expression_mirroring/expression_mirroring_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/parent_mode/parent_dashboard_screen.dart';
import 'screens/parent_mode/pin_entry_screen.dart';
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
    redirect: (context, state) {
      final hasName = progressProvider.progress.childName.isNotEmpty;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasName && !isOnboarding) return '/onboarding';
      if (hasName && isOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
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
          seedColor: const Color(0xFFFFB347),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
    );
  }
}

