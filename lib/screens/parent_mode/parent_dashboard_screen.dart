import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';

// ─── Green Design Tokens ──────────────────────────────────────────────────────
const _brandGreen  = Color(0xFF4CAF6E);
const _brandShadow = Color(0xFF2A7A48);
const _bg          = Color(0xFFEDFFF3);
const _textColor   = Color(0xFF1A3A2A);
const _mutedText   = Color(0xFF557A65);

/// Parent Dashboard — PIN-protected adult controls.
///
/// Features:
///   • View child progress (links to ProgressScreen)
///   • Set / change child's name
///   • Export session data as CSV (thesis data collection)
///   • Reset all progress
///   • Tip sheet: how to guide children through each game
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
                'Lihat detail bintang dan progres',
                style: TextStyle(color: _textColor),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: _mutedText),
              onTap: () => context.push('/progress'),
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
                  'Buka ringkasan data sesi bermain untuk keperluan penelitian.',
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
          const _DashboardSection(
            title: 'PANDUAN PENDAMPINGAN',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TipItem(
                  icon: Icons.face,
                  title: 'Raccoo Feel Cards',
                  tip:
                      'Ajak anak menyentuh kartu yang diminta Raccoo sambil mengulang nama 6 emosi dasar.',
                ),
                SizedBox(height: 8),
                _TipItem(
                  icon: Icons.camera_front,
                  title: 'Tiru Ekspresi',
                  tip:
                      'Duduk di depan anak dan tunjukkan ekspresi contoh bersama-sama.',
                ),
                SizedBox(height: 8),
                _TipItem(
                  icon: Icons.groups,
                  title: 'Situasi Sosial',
                  tip:
                      'Setelah bermain, diskusikan: "Kenapa kita merasa seperti itu?"',
                ),
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
            child:
                const Text('Reset', style: TextStyle(color: Colors.red)),
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
            value: '${progress.totalStars}/9',
          ),
          _SummaryItem(
            icon: Icons.sports_esports_rounded,
            label: 'Sesi',
            value: '${progress.totalSessions}',
          ),
          _SummaryItem(
            icon: Icons.check_circle_rounded,
            label: 'Benar',
            value: '${progress.totalCorrect}',
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
