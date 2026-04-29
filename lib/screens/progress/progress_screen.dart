import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game_feature_catalog.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';

/// Progress screen — shown from the Parent Dashboard.
///
/// Displays active-feature counts, correct responses, and overall accuracy.
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama: ${progress.childName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Laporan ini fokus pada tiga fitur aktif di menu utama: Raccoo Feel Cards, Raccoo Mirror, dan Raccoo Think.',
                    style: TextStyle(color: Colors.brown, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Khusus Raccoo Think, hasil sesi level dibaca dengan patokan 6 soal dan kategori Mahir, Berkembang, Mulai Tumbuh, atau Perlu Bimbingan.',
                    style: TextStyle(color: Colors.brown, fontSize: 13),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Catatan pembacaan data: angka yang tersimpan adalah data bermain atau respons yang berhasil dicatat sistem. Untuk Raccoo Think, kategori sesi dibaca dari 6 soal per level, sedangkan kartu ini tetap menampilkan rekap akumulasi data yang tersimpan.',
              style: TextStyle(color: Colors.brown, fontSize: 13, height: 1.5),
            ),
          ),
          if (totalRecordsForActiveGames(progress) == 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Belum ada data dari fitur aktif. Coba selesaikan satu permainan dulu, lalu ringkasannya muncul di sini.',
                style: TextStyle(color: Colors.brown, fontSize: 14),
              ),
            )
          else ...[
            ...activeGameFeatures.map(
              (feature) => _GameStatCard(feature: feature, progress: progress),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameStatCard extends StatelessWidget {
  final GameFeatureMeta feature;
  final GameProgress progress;

  const _GameStatCard({required this.feature, required this.progress});

  @override
  Widget build(BuildContext context) {
    final plays = progress.playCounts[feature.id] ?? 0;
    final correct = progress.correctCounts[feature.id] ?? 0;
    final accuracy = progress.accuracyFor(feature.id);
    final stars = progress.starsFor(feature.id);
    final lastPlayed = progress.lastPlayed[feature.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(feature.icon, color: feature.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.summary,
                        style: const TextStyle(
                          color: Colors.brown,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StarRow(stars: stars, color: feature.color),
            const SizedBox(height: 12),
            if (plays == 0)
              Text(
                'Belum ada data tercatat.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              )
            else ...[
              _StatRow(label: 'Data tercatat', value: '$plays'),
              _StatRow(label: 'Respons tepat', value: '$correct'),
              _StatRow(
                label: 'Ketepatan',
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feature.trackingNote,
                style: TextStyle(
                  color: feature.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
            if (feature.id == GameProgress.gameSocialSituations) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patokan kategori sesi 6 soal',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    _ThinkRuleRow(label: 'Mahir', detail: '5-6 benar'),
                    SizedBox(height: 6),
                    _ThinkRuleRow(label: 'Berkembang', detail: '3-4 benar'),
                    SizedBox(height: 6),
                    _ThinkRuleRow(label: 'Mulai Tumbuh', detail: '1-2 benar'),
                    SizedBox(height: 6),
                    _ThinkRuleRow(label: 'Perlu Bimbingan', detail: '0 benar'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ThinkRuleRow extends StatelessWidget {
  final String label;
  final String detail;

  const _ThinkRuleRow({
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.brown,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            color: Colors.brown,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;
  final Color color;

  const _StarRow({required this.stars, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Icon(
            index < stars ? Icons.star_rounded : Icons.star_border_rounded,
            color: index < stars ? color : Colors.grey.shade400,
            size: 28,
          ),
        ),
      ),
    );
  }
}
