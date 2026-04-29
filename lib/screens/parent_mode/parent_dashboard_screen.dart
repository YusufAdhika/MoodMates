import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game_feature_catalog.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';

// ─── Green Design Tokens ──────────────────────────────────────────────────────
const _brandGreen = Color(0xFF4CAF6E);
const _brandShadow = Color(0xFF2A7A48);
const _bg = Color(0xFFEDFFF3);
const _textColor = Color(0xFF1A3A2A);
const _mutedText = Color(0xFF557A65);

/// Parent Dashboard — PIN-protected adult controls.
///
/// Features:
///   • View child progress (links to ProgressScreen)
///   • Set / change child's name
///   • Export active-feature data as CSV (thesis data collection)
///   • Reset all progress
///   • Tip sheet: how to guide children through active games
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>().progress;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Dashboard Orang Tua',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SummaryCard(progress: progress),
          const SizedBox(height: 16),

          // Child name
          _DashboardSection(
            title: 'NAMA ANAK',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    progress.childName.isNotEmpty
                        ? progress.childName
                        : 'Belum diatur',
                    style: TextStyle(
                      fontSize: 18,
                      color: progress.childName.isNotEmpty
                          ? _textColor
                          : _mutedText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showNameDialog(context),
                  style: TextButton.styleFrom(foregroundColor: _brandGreen),
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _DashboardSection(
            title: 'PROFIL ANAK',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.switch_account, color: _brandGreen),
              title: const Text(
                'Pilih, tambah, atau hapus profil anak',
                style: TextStyle(color: _textColor),
              ),
              subtitle: const Text(
                'Hapus profil perlu PIN orang tua.',
                style: TextStyle(color: _mutedText),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: _mutedText),
              onTap: () => context.push('/profiles'),
            ),
          ),
          const SizedBox(height: 16),

          // Progress
          _DashboardSection(
            title: 'PERKEMBANGAN',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bar_chart, color: _brandGreen),
              title: const Text(
                'Lihat ringkasan tiga fitur aktif',
                style: TextStyle(color: _textColor),
              ),
              subtitle: const Text(
                'Menampilkan data Raccoo Feel Cards, Raccoo Mirror, dan Raccoo Think.',
                style: TextStyle(color: _mutedText),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: _mutedText),
              onTap: () => context.push('/progress'),
            ),
          ),
          const SizedBox(height: 16),

          _DashboardSection(
            title: 'FITUR AKTIF SAAT INI',
            child: Column(
              children: [
                for (final feature in activeGameFeatures) ...[
                  _FeatureItem(feature: feature),
                  if (feature != activeGameFeatures.last)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          const _DashboardSection(
            title: 'PENILAIAN RACCOO THINK',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patokan sesi saat ini memakai 6 soal per level.',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rumus: Skor Sesi = (Jumlah Jawaban Benar / 6) x 100',
                  style: TextStyle(color: _mutedText, fontSize: 13),
                ),
                SizedBox(height: 12),
                _AssessmentLegendItem(label: 'Mahir', detail: '5-6 benar'),
                SizedBox(height: 8),
                _AssessmentLegendItem(label: 'Berkembang', detail: '3-4 benar'),
                SizedBox(height: 8),
                _AssessmentLegendItem(
                    label: 'Mulai Tumbuh', detail: '1-2 benar'),
                SizedBox(height: 8),
                _AssessmentLegendItem(
                    label: 'Perlu Bimbingan', detail: '0 benar'),
                SizedBox(height: 12),
                Text(
                  'Bagian ini membaca hasil sesi level. Kalau nanti ingin laporan semester, data sesi perlu direkap per periode.',
                  style:
                      TextStyle(color: _mutedText, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CSV export
          _DashboardSection(
            title: 'EKSPOR DATA (CSV)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buka ringkasan data tiga fitur aktif dengan nama fitur yang sesuai menu saat ini.',
                  style: TextStyle(color: _mutedText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportCsv(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Lihat Data CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tips
          _DashboardSection(
            title: 'PANDUAN PENDAMPINGAN',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final feature in activeGameFeatures) ...[
                  _TipItem(
                    icon: feature.icon,
                    title: feature.title,
                    tip: feature.parentTip,
                  ),
                  if (feature != activeGameFeatures.last)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reset progress
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.refresh, color: Colors.red),
            label: const Text(
              'Reset Semua Data Bermain',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: context.read<ProgressProvider>().progress.childName,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nama Anak'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Masukkan nama anak'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _mutedText),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: _brandGreen),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<ProgressProvider>().setChildName(name);
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final provider = context.read<ProgressProvider>();
    final csv = provider.exportCsv();

    // TODO: use share_plus package to share the CSV via WhatsApp/email.
    // For now, show the CSV in a dialog for thesis testing.
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Data CSV'),
          content: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: _brandGreen),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset semua progres?'),
        content: const Text('Data permainan anak akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: _mutedText),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<ProgressProvider>().reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progres berhasil direset.')),
        );
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final GameProgress progress;

  const _SummaryCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final totalStars = totalStarsForActiveGames(progress);
    final totalRecords = totalRecordsForActiveGames(progress);
    final totalCorrect = totalCorrectForActiveGames(progress);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6DD68A), Color(0xFF4CAF6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _brandShadow,
            offset: Offset(4, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.star_rounded,
            label: 'Bintang',
            value: '$totalStars/${activeGameFeatures.length * 3}',
          ),
          _SummaryItem(
            icon: Icons.sports_esports_rounded,
            label: 'Catatan',
            value: '$totalRecords',
          ),
          _SummaryItem(
            icon: Icons.check_circle_rounded,
            label: 'Benar',
            value: '$totalCorrect',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: _mutedText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final GameFeatureMeta feature;

  const _FeatureItem({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: feature.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: feature.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.summary,
                style: const TextStyle(color: _mutedText, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                feature.trackingNote,
                style: TextStyle(
                  color: feature.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssessmentLegendItem extends StatelessWidget {
  final String label;
  final String detail;

  const _AssessmentLegendItem({
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
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            color: _mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tip;

  const _TipItem({
    required this.icon,
    required this.title,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _brandGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Text(
                tip,
                style: const TextStyle(color: _mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
