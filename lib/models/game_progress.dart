/// Tracks one child's play sessions across all three mini-games.
/// Serialised to JSON and stored via StorageService (shared_preferences).
class GameProgress {
  final String childName;
  final Map<String, int> playCounts;         // gameId → total sessions played
  final Map<String, int> correctCounts;      // gameId → total correct answers
  final Map<String, DateTime?> lastPlayed;   // gameId → last session timestamp

  static const String gameEmotionRecognition = 'emotion_recognition';
  static const String gameExpressionMirroring = 'expression_mirroring';
  static const String gameSocialSituations = 'social_situations';

  static const List<String> allGameIds = [
    gameEmotionRecognition,
    gameExpressionMirroring,
    gameSocialSituations,
  ];

  const GameProgress({
    required this.childName,
    required this.playCounts,
    required this.correctCounts,
    required this.lastPlayed,
  });

  factory GameProgress.empty({String childName = ''}) {
    return GameProgress(
      childName: childName,
      playCounts: {for (final id in allGameIds) id: 0},
      correctCounts: {for (final id in allGameIds) id: 0},
      lastPlayed: {for (final id in allGameIds) id: null},
    );
  }

  /// Returns accuracy (0.0–1.0) for a given game, or null if never played.
  double? accuracyFor(String gameId) {
    final plays = playCounts[gameId] ?? 0;
    if (plays == 0) return null;
    return (correctCounts[gameId] ?? 0) / plays;
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
      childName: childName,
      playCounts: newCounts,
      correctCounts: newCorrect,
      lastPlayed: newLastPlayed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'playCounts': playCounts,
      'correctCounts': correctCounts,
      'lastPlayed': lastPlayed.map(
        (k, v) => MapEntry(k, v?.toIso8601String()),
      ),
    };
  }

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      childName: json['childName'] as String? ?? '',
      playCounts: Map<String, int>.from(json['playCounts'] as Map? ?? {}),
      correctCounts: Map<String, int>.from(json['correctCounts'] as Map? ?? {}),
      lastPlayed: (json['lastPlayed'] as Map? ?? {}).map(
        (k, v) => MapEntry(
          k as String,
          v == null ? null : DateTime.tryParse(v as String),
        ),
      ),
    );
  }
}
