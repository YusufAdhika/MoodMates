import 'package:flutter/foundation.dart';
import '../models/game_progress.dart';
import '../services/storage_service.dart';

/// Holds the current child's GameProgress in memory and syncs to StorageService.
///
/// Screens read progress via context.watch<ProgressProvider>().progress
/// and record sessions via context.read<ProgressProvider>().recordSession(...)
class ProgressProvider extends ChangeNotifier {
  final StorageService _storage;

  GameProgress _progress = GameProgress.empty();

  GameProgress get progress => _progress;

  ProgressProvider(this._storage);

  Future<void> load() async {
    _progress = await _storage.loadProgress();
    notifyListeners();
  }

  /// Call after each game session (correct or incorrect answer round).
  Future<void> recordSession({
    required String gameId,
    required bool wasCorrect,
  }) async {
    _progress = _progress.copyWithSession(
      gameId: gameId,
      wasCorrect: wasCorrect,
    );
    notifyListeners();
    final saved = await _storage.saveProgress(_progress);
    if (!saved) {
      debugPrint('[ProgressProvider] Warning: progress not saved for $gameId');
    }
  }

  Future<void> setChildName(String name) async {
    _progress = GameProgress(
      childName: name,
      playCounts: _progress.playCounts,
      correctCounts: _progress.correctCounts,
      lastPlayed: _progress.lastPlayed,
    );
    notifyListeners();
    await _storage.saveProgress(_progress);
  }

  Future<void> reset() async {
    await _storage.clearProgress();
    _progress = GameProgress.empty();
    notifyListeners();
  }

  /// Exports session data as CSV rows for thesis data collection.
  /// Returns CSV string with header row.
  String exportCsv() {
    final buffer = StringBuffer();
    buffer.writeln('game,sessions,correct,accuracy,last_played');
    for (final gameId in GameProgress.allGameIds) {
      final sessions = _progress.playCounts[gameId] ?? 0;
      final correct = _progress.correctCounts[gameId] ?? 0;
      final accuracy = sessions > 0
          ? (correct / sessions * 100).toStringAsFixed(1)
          : '-';
      final lastPlayed = _progress.lastPlayed[gameId]?.toIso8601String() ?? '-';
      buffer.writeln('$gameId,$sessions,$correct,$accuracy%,$lastPlayed');
    }
    return buffer.toString();
  }
}
