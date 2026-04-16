/// Tracks one child's play sessions across all three mini-games.
/// Serialised to JSON and stored via StorageService (shared_preferences).
class GameProgress {
  /// Unique profile ID — epoch milliseconds as string, set once at creation.
  final String id;
  final String childName;
  final Map<String, int> playCounts; // gameId → total sessions played
  final Map<String, int> correctCounts; // gameId → total correct answers
  final Map<String, DateTime?> lastPlayed; // gameId → last session timestamp

  static const String gameEmotionRecognition = 'emotion_recognition';
  static const String gameExpressionMirroring = 'expression_mirroring';
  static const String gameSocialSituations = 'social_situations';
  static const String gameFeelCards = 'feel_cards';

  static const List<String> allGameIds = [
    gameEmotionRecognition,
    gameExpressionMirroring,
    gameSocialSituations,
    gameFeelCards,
  ];

  const GameProgress({
    required this.id,
    required this.childName,
    required this.playCounts,
    required this.correctCounts,
    required this.lastPlayed,
  });

  factory GameProgress.empty({String childName = '', String? id}) {
    final profileId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    return GameProgress(
      id: profileId,
      childName: childName,
      playCounts: {for (final gId in allGameIds) gId: 0},
      correctCounts: {for (final gId in allGameIds) gId: 0},
      lastPlayed: {for (final gId in allGameIds) gId: null},
    );
  }

  /// Returns accuracy (0.0–1.0) for a given game, or null if never played.
  double? accuracyFor(String gameId) {
    final plays = playCounts[gameId] ?? 0;
    if (plays == 0) return null;
    return (correctCounts[gameId] ?? 0) / plays;
  }

  int starsFor(String gameId) {
    final accuracy = accuracyFor(gameId);
    if (accuracy == null) return 0;
    if (accuracy >= 0.8) return 3;
    if (accuracy >= 0.5) return 2;
    return 1;
  }

  int get totalStars {
    return allGameIds.fold(0, (total, gameId) => total + starsFor(gameId));
  }

  int get totalSessions {
    return playCounts.values.fold(0, (total, count) => total + count);
  }

  int get totalCorrect {
    return correctCounts.values.fold(0, (total, count) => total + count);
  }

  GameProgress copyWithSession({
    required String gameId,
    required bool wasCorrect,
  }) {
    final newCounts = Map<String, int>.from(playCounts);
    final newCorrect = Map<String, int>.from(correctCounts);
    final newLastPlayed = Map<String, DateTime?>.from(lastPlayed);

    newCounts[gameId] = (newCounts[gameId] ?? 0) + 1;
    if (wasCorrect) {
      newCorrect[gameId] = (newCorrect[gameId] ?? 0) + 1;
    }
    newLastPlayed[gameId] = DateTime.now();

    return GameProgress(
      id: id,
      childName: childName,
      playCounts: newCounts,
      correctCounts: newCorrect,
      lastPlayed: newLastPlayed,
    );
  }

  GameProgress copyWithName(String name) {
    return GameProgress(
      id: id,
      childName: name,
      playCounts: playCounts,
      correctCounts: correctCounts,
      lastPlayed: lastPlayed,
    );
  }

  GameProgress copyWithResetStats() {
    return GameProgress.empty(childName: childName, id: id);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childName': childName,
      'playCounts': playCounts,
      'correctCounts': correctCounts,
      'lastPlayed': lastPlayed.map(
        (k, v) => MapEntry(k, v?.toIso8601String()),
      ),
    };
  }

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    try {
      return GameProgress(
        id: json['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        childName: json['childName'] as String? ?? '',
        playCounts: Map<String, int>.from(json['playCounts'] as Map? ?? {}),
        correctCounts:
            Map<String, int>.from(json['correctCounts'] as Map? ?? {}),
        lastPlayed: (json['lastPlayed'] as Map? ?? {}).map(
          (k, v) => MapEntry(
            k as String,
            v == null ? null : DateTime.tryParse(v as String),
          ),
        ),
      );
    } catch (_) {
      // Data korup atau format lama — mulai dari awal daripada crash.
      return GameProgress.empty();
    }
  }
}
