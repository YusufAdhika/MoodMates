import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';

/// Progress screen — shown from the Parent Dashboard.
///
/// Displays per-game session counts, correct/incorrect counts, and accuracy.
/// Data is read from ProgressProvider (local shared_preferences).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB347),
        title: const Text('Perkembangan Anak'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (progress.childName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Nama: ${progress.childName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
          ...GameProgress.allGameIds.map(
            (id) => _GameStatCard(gameId: id, progress: progress),
          ),
        ],
      ),
    );
  }
}

class _GameStatCard extends StatelessWidget {
  final String gameId;
  final GameProgress progress;

  const _GameStatCard({required this.gameId, required this.progress});

  @override
  Widget build(BuildContext context) {
    final plays = progress.playCounts[gameId] ?? 0;
    final correct = progress.correctCounts[gameId] ?? 0;
    final accuracy = progress.accuracyFor(gameId);
    final lastPlayed = progress.lastPlayed[gameId];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_gameIcon(gameId), color: _gameColor(gameId), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _gameName(gameId),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plays == 0)
              const Text(
                'Belum ada permainan',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            else ...[
              _StatRow(label: 'Jumlah sesi', value: '$plays'),
              _StatRow(label: 'Jawaban benar', value: '$correct'),
              _StatRow(
                label: 'Akurasi',
                value: accuracy != null
                    ? '${(accuracy * 100).toStringAsFixed(0)}%'
                    : '-',
              ),
              if (lastPlayed != null)
                _StatRow(
                  label: 'Terakhir dimainkan',
                  value: _formatDate(lastPlayed),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _gameName(String id) {
    switch (id) {
      case GameProgress.gameEmotionRecognition:
        return 'Kenali Emosi';
      case GameProgress.gameExpressionMirroring:
        return 'Tiru Ekspresi';
      case GameProgress.gameSocialSituations:
        return 'Situasi Sosial';
      default:
        return id;
    }
  }

  IconData _gameIcon(String id) {
    switch (id) {
      case GameProgress.gameEmotionRecognition:
        return Icons.face;
      case GameProgress.gameExpressionMirroring:
        return Icons.camera_front;
      case GameProgress.gameSocialSituations:
        return Icons.groups;
      default:
        return Icons.games;
    }
  }

  Color _gameColor(String id) {
    switch (id) {
      case GameProgress.gameEmotionRecognition:
        return Colors.orange;
      case GameProgress.gameExpressionMirroring:
        return Colors.blue;
      case GameProgress.gameSocialSituations:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
