import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/progress_provider.dart';
import 'screens/emotion_recognition/emotion_recognition_screen.dart';
import 'screens/expression_mirroring/expression_mirroring_screen.dart';
import 'screens/home/home_screen.dart';
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

final _router = GoRouter(
  initialLocation: '/',
  routes: [
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

class MoodmatesApp extends StatelessWidget {
  const MoodmatesApp({super.key});

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
