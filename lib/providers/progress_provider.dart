import 'package:flutter/foundation.dart';
import '../models/game_feature_catalog.dart';
import '../models/game_progress.dart';
import '../services/storage_service.dart';

/// Manages the list of all child profiles and tracks the active one.
///
/// Usage:
///   context.watch<ProgressProvider>().progress   → active profile's progress
///   context.watch<ProgressProvider>().profiles   → all profiles
///   context.read<ProgressProvider>().switchProfile(id)
///   context.read<ProgressProvider>().addProfile(name)
///   context.read<ProgressProvider>().deleteProfile(id)
class ProgressProvider extends ChangeNotifier {
  final StorageService _storage;

  List<GameProgress> _profiles = [];
  GameProgress? _activeProfile;

  List<GameProgress> get profiles => List.unmodifiable(_profiles);

  /// Active profile's progress. Falls back to empty if nothing is active.
  GameProgress get progress => _activeProfile ?? GameProgress.empty(id: '');

  bool get hasActiveProfile => _activeProfile != null;
  bool get hasAnyProfile => _profiles.isNotEmpty;

  ProgressProvider(this._storage);

  Future<void> load() async {
    _profiles = _storage.loadAllProfiles();
    final activeId = _storage.activeProfileId;
    if (activeId != null) {
      _activeProfile = _profiles.cast<GameProgress?>().firstWhere(
            (p) => p?.id == activeId,
            orElse: () => null,
          );
    }
    // If active ID points to deleted profile, fall back to first available
    if (_activeProfile == null && _profiles.isNotEmpty) {
      _activeProfile = _profiles.first;
      await _storage.setActiveProfileId(_activeProfile!.id);
    }
    notifyListeners();
  }

  /// Switch the active profile. No-op if ID not found.
  Future<void> switchProfile(String id) async {
    final profile = _profiles.cast<GameProgress?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (profile == null) return;
    _activeProfile = profile;
    await _storage.setActiveProfileId(id);
    notifyListeners();
  }

  /// Create a new child profile and make it active.
  Future<GameProgress> addProfile(String childName) async {
    final newProfile = await _storage.addProfile(childName);
    _profiles = _storage.loadAllProfiles();
    _activeProfile = newProfile;
    await _storage.setActiveProfileId(newProfile.id);
    notifyListeners();
    return newProfile;
  }

  /// Delete a profile by ID. If it was the active one, switches to first remaining.
  /// Returns false if not found.
  Future<bool> deleteProfile(String id) async {
    final deleted = await _storage.deleteProfile(id);
    if (!deleted) return false;
    _profiles = _storage.loadAllProfiles();
    if (_activeProfile?.id == id) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
      if (_activeProfile != null) {
        await _storage.setActiveProfileId(_activeProfile!.id);
      }
    }
    notifyListeners();
    return true;
  }

  /// Call after each game session (correct or incorrect answer round).
  Future<void> recordSession({
    required String gameId,
    required bool wasCorrect,
  }) async {
    if (_activeProfile == null) return;
    _activeProfile = _activeProfile!.copyWithSession(
      gameId: gameId,
      wasCorrect: wasCorrect,
    );
    _updateActiveInList();
    notifyListeners();
    final saved = await _storage.saveProfile(_activeProfile!);
    if (!saved) {
      debugPrint('[ProgressProvider] Warning: progress not saved for $gameId');
    }
  }

  Future<void> setChildName(String name) async {
    if (_activeProfile == null) return;
    _activeProfile = _activeProfile!.copyWithName(name);
    _updateActiveInList();
    notifyListeners();
    await _storage.saveProfile(_activeProfile!);
  }

  Future<void> reset() async {
    if (_activeProfile == null) return;
    _activeProfile = _activeProfile!.copyWithResetStats();
    _updateActiveInList();
    notifyListeners();
    await _storage.saveProfile(_activeProfile!);
  }

  /// Exports active profile's session data as CSV for thesis data collection.
  String exportCsv() {
    final p = progress;
    final buffer = StringBuffer();
    buffer.writeln(
        'child,game_id,game_name,records,correct,accuracy,last_played');
    for (final feature in activeGameFeatures) {
      final records = p.playCounts[feature.id] ?? 0;
      final correct = p.correctCounts[feature.id] ?? 0;
      final accuracy =
          records > 0 ? (correct / records * 100).toStringAsFixed(1) : '-';
      final lastPlayed = p.lastPlayed[feature.id]?.toIso8601String() ?? '-';
      buffer.writeln(
          '${p.childName},${feature.id},${feature.title},$records,$correct,$accuracy%,$lastPlayed');
    }
    return buffer.toString();
  }

  void _updateActiveInList() {
    if (_activeProfile == null) return;
    final idx = _profiles.indexWhere((p) => p.id == _activeProfile!.id);
    if (idx != -1) {
      _profiles = List<GameProgress>.from(_profiles)..[idx] = _activeProfile!;
    }
  }
}
