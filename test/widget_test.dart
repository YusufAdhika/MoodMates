import 'package:flutter_test/flutter_test.dart';
import 'package:moodmates/screens/home/home_screen.dart';
import 'package:moodmates/providers/progress_provider.dart';
import 'package:moodmates/services/audio_service.dart';
import 'package:moodmates/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Minimal test that verifies the HomeScreen renders without crashing.
/// Full game widget tests live in test/screens/.
void main() {
  testWidgets('HomeScreen renders game menu buttons', (WidgetTester tester) async {
    final storageService = StorageService();
    await storageService.init();
    final progressProvider = ProgressProvider(storageService);
    await progressProvider.load();

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          Provider<AudioService>.value(value: AudioService()),
          ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('Kenali Emosi'), findsOneWidget);
    expect(find.text('Tiru Ekspresi'), findsOneWidget);
    expect(find.text('Situasi Sosial'), findsOneWidget);
  });
}
