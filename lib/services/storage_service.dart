import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_progress.dart';

/// Local persistence layer.
///
/// Abstracted so the implementation can be swapped for Firebase later
/// without touching any screen or provider code.
///
/// Keys stored in shared_preferences:
///   _kProgress  → JSON-encoded GameProgress
///   _kPin       → SHA-256 hex of the parent PIN (null if not set)
///   _kSchemaVer → int, incremented on breaking data-format changes
class StorageService {
  static const _kProgress = 'moodmates_progress';
  static const _kPin = 'moodmates_pin_hash';
  static const _kSchemaVer = 'moodmates_schema_version';
  static const _currentSchemaVersion = 1;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded();
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  Future<GameProgress> loadProgress() async {
    final raw = _prefs.getString(_kProgress);
    if (raw == null) return GameProgress.empty();
    try {
      return GameProgress.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('[StorageService] Failed to parse progress: $e');
      return GameProgress.empty();
    }
  }

  Future<bool> saveProgress(GameProgress progress) async {
    try {
      return await _prefs.setString(
        _kProgress,
        json.encode(progress.toJson()),
      );
    } catch (e) {
      debugPrint('[StorageService] Failed to save progress: $e');
      return false;
    }
  }

  Future<bool> clearProgress() async {
    return _prefs.remove(_kProgress);
  }

  // ── PIN ───────────────────────────────────────────────────────────────────

  bool get hasPin => _prefs.containsKey(_kPin);

  /// Stores a SHA-256 hash of [pin]. Never stores the raw PIN.
  Future<bool> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return _prefs.setString(_kPin, hash);
  }

  /// Returns true if [pin] matches the stored hash.
  bool validatePin(String pin) {
    final stored = _prefs.getString(_kPin);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  Future<bool> clearPin() async {
    return _prefs.remove(_kPin);
  }

  // ── Schema migration ──────────────────────────────────────────────────────

  Future<void> _migrateIfNeeded() async {
    final version = _prefs.getInt(_kSchemaVer) ?? 0;
    if (version < _currentSchemaVersion) {
      // Future migrations go here: if (version < 2) { ... }
      await _prefs.setInt(_kSchemaVer, _currentSchemaVersion);
      debugPrint('[StorageService] Migrated schema to v$_currentSchemaVersion');
    }
  }
}
