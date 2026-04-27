import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_progress.dart';

/// Local persistence layer.
///
/// Keys stored in shared_preferences:
///   _kProfiles         → JSON-encoded List<GameProgress>  (all child profiles)
///   _kActiveProfileId  → String ID of the currently active profile
///   _kPin              → SHA-256 hex of the parent PIN
///   _kSchemaVer        → int, incremented on breaking data-format changes
///
/// Legacy key (schema v1, migrated on first run):
///   _kProgressLegacy   → single-profile JSON (migrated into _kProfiles list)
class StorageService {
  static const _kProfiles = 'moodmates_profiles';
  static const _kActiveProfileId = 'moodmates_active_profile_id';
  static const _kPin = 'moodmates_pin_hash';
  static const _kSchemaVer = 'moodmates_schema_version';
  static const _kProgressLegacy = 'moodmates_progress'; // v1 key
  static const _currentSchemaVersion = 2;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded();
  }

  // ── Profiles ──────────────────────────────────────────────────────────────

  /// Load all stored child profiles.
  List<GameProgress> loadAllProfiles() {
    final raw = _prefs.getString(_kProfiles);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => GameProgress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[StorageService] Failed to parse profiles: $e');
      return [];
    }
  }

  Future<bool> saveAllProfiles(List<GameProgress> profiles) async {
    try {
      return await _prefs.setString(
        _kProfiles,
        json.encode(profiles.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[StorageService] Failed to save profiles: $e');
      return false;
    }
  }

  /// Add a new profile. Returns the created profile.
  Future<GameProgress> addProfile(String childName) async {
    final profiles = loadAllProfiles();
    final newProfile = GameProgress.empty(childName: childName);
    profiles.add(newProfile);
    await saveAllProfiles(profiles);
    return newProfile;
  }

  /// Delete a profile by ID. Returns true if found and deleted.
  Future<bool> deleteProfile(String profileId) async {
    final profiles = loadAllProfiles();
    final before = profiles.length;
    profiles.removeWhere((p) => p.id == profileId);
    if (profiles.length == before) return false; // not found
    await saveAllProfiles(profiles);
    // If deleted profile was active, clear active ID
    if (_prefs.getString(_kActiveProfileId) == profileId) {
      await _prefs.remove(_kActiveProfileId);
    }
    return true;
  }

  /// Save a single updated profile back into the list.
  Future<bool> saveProfile(GameProgress updated) async {
    final profiles = loadAllProfiles();
    final idx = profiles.indexWhere((p) => p.id == updated.id);
    if (idx == -1) {
      profiles.add(updated);
    } else {
      profiles[idx] = updated;
    }
    return saveAllProfiles(profiles);
  }

  // ── Active Profile ────────────────────────────────────────────────────────

  String? get activeProfileId => _prefs.getString(_kActiveProfileId);

  Future<bool> setActiveProfileId(String id) async {
    return _prefs.setString(_kActiveProfileId, id);
  }

  Future<bool> clearActiveProfileId() async {
    return _prefs.remove(_kActiveProfileId);
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

  // ── Social Situations Resume State ───────────────────────────────────────

  static const _kSocialResume = 'social_situations_resume';

  Future<void> saveSocialSituationsResume(
      String profileId, Map<String, dynamic> state) async {
    await _prefs.setString(
        '${_kSocialResume}_$profileId', json.encode(state));
  }

  Map<String, dynamic>? loadSocialSituationsResume(String profileId) {
    final raw = _prefs.getString('${_kSocialResume}_$profileId');
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSocialSituationsResume(String profileId) async {
    await _prefs.remove('${_kSocialResume}_$profileId');
  }

  // ── Schema migration ──────────────────────────────────────────────────────

  Future<void> _migrateIfNeeded() async {
    final version = _prefs.getInt(_kSchemaVer) ?? 0;

    if (version < 2) {
      // v1 → v2: single profile in _kProgressLegacy → profiles list
      final legacyRaw = _prefs.getString(_kProgressLegacy);
      if (legacyRaw != null) {
        try {
          final legacy = GameProgress.fromJson(
            json.decode(legacyRaw) as Map<String, dynamic>,
          );
          // Only migrate if there's actual data (has a name)
          if (legacy.childName.isNotEmpty) {
            final existing = loadAllProfiles();
            if (existing.isEmpty) {
              await saveAllProfiles([legacy]);
              await setActiveProfileId(legacy.id);
            }
          }
        } catch (e) {
          debugPrint('[StorageService] Migration v1→v2 failed: $e');
        }
        await _prefs.remove(_kProgressLegacy);
      }
      await _prefs.setInt(_kSchemaVer, _currentSchemaVersion);
      debugPrint('[StorageService] Migrated schema to v$_currentSchemaVersion');
    }
  }
}
