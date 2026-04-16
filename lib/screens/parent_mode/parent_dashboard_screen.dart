import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game_progress.dart';
import '../../providers/progress_provider.dart';

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
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB347),
        title: const Text('Dashboard Orang Tua'),
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
            title: 'Nama Anak',
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
                          ? Colors.brown
                          : Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showNameDialog(context),
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _DashboardSection(
            title: 'Profil Anak',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.switch_account, color: Colors.orange),
              title: const Text('Pilih, tambah, atau hapus profil anak'),
              subtitle: const Text('Hapus profil perlu PIN orang tua.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/profiles'),
            ),
          ),
          const SizedBox(height: 16),

          // Progress
          _DashboardSection(
            title: 'Perkembangan',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bar_chart, color: Colors.orange),
              title: const Text('Lihat detail bintang dan progres'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/progress'),
            ),
          ),
          const SizedBox(height: 16),

          // CSV export
          _DashboardSection(
            title: 'Ekspor Data (CSV)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buka ringkasan data sesi bermain untuk keperluan penelitian.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportCsv(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Lihat Data CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tips
          const _DashboardSection(
            title: 'Panduan Pendampingan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TipItem(
                  icon: Icons.face,
                  title: 'Kenali Emosi',
                  tip:
                      'Tunjuk karakter dan tanya: "Menurutmu ini perasaan apa?"',
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
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD27D), Color(0xFFFFB347)],
        ),
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.brown.withValues(alpha: 0.08),
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
              fontSize: 14,
              color: Colors.grey,
              letterSpacing: 0.5,
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
        Icon(icon, size: 20, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(tip,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
