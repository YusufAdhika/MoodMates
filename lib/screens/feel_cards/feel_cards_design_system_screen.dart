import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FeelCardsDesignSystemScreen extends StatelessWidget {
  const FeelCardsDesignSystemScreen({super.key});

  static const Color _bg = Color(0xFFFFF3E0);
  static const Color _surface = Color(0xFFFFF8E7);
  static const Color _text = Color(0xFF3D2B1A);
  static const Color _muted = Color(0xFF8D6E63);
  static const Color _brand = Color(0xFFFF9A3C);
  static const Color _brandShadow = Color(0xFFC85A00);
  static const Color _accentBlue = Color(0xFF4BA3C3);
  static const Color _accentBlueShadow = Color(0xFF1464A0);
  static const Color _accentGreen = Color(0xFF4CAF6E);
  static const Color _accentGreenShadow = Color(0xFF1A5E36);
  static const Color _accentGold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onBack: () => context.pop()),
              const SizedBox(height: 20),
              const _HeroCard(),
              const SizedBox(height: 20),
              const _SectionTitle(
                eyebrow: 'Recommended Direction',
                title: 'Passport + Toy Flashcard',
                description:
                    'Struktur utama tetap flashcard, tetapi progress dan penyajian konten dibingkai seperti perjalanan koleksi emosi.',
              ),
              const SizedBox(height: 12),
              const _DecisionCard(
                title: 'Kenapa ini yang paling masuk akal',
                color: _brand,
                shadowColor: _brandShadow,
                bullets: [
                  'Mudah diturunkan dari struktur screen yang sekarang.',
                  'Punya identitas lebih kuat daripada flashcard biasa.',
                  'Masih sangat jelas dan nyaman untuk anak usia 4–6 tahun.',
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                eyebrow: 'Concept Options',
                title: 'Tiga Arah Visual',
                description:
                    'Gunakan halaman ini untuk memilih bahasa visual sebelum kita pindah ke implementasi final.',
              ),
              const SizedBox(height: 12),
              const _ConceptCard(
                title: 'A. Toy Flashcard',
                subtitle: 'Tactile, hangat, langsung kebaca.',
                badge: 'Paling aman',
                color: _brand,
                shadowColor: _brandShadow,
                strengths: [
                  'Komponen besar dan mudah disentuh.',
                  'Shadow keras terasa seperti mainan fisik.',
                  'Paling dekat dengan UI sekarang.',
                ],
                layoutNotes:
                    'Card depan punya teaser ekspresi samar, card belakang dibagi jelas menjadi video, nama emosi, speech bubble, dan chips contoh situasi.',
              ),
              const SizedBox(height: 16),
              const _ConceptCard(
                title: 'B. Emotion Passport',
                subtitle: 'Belajar terasa seperti perjalanan koleksi.',
                badge: 'Paling khas',
                color: _accentBlue,
                shadowColor: _accentBlueShadow,
                strengths: [
                  'Progress terasa bermakna dan memorable.',
                  'Done screen bisa terasa seperti koleksi stempel.',
                  'Memberi identitas kuat untuk fitur Feel Cards.',
                ],
                layoutNotes:
                    'Setiap emosi tampil seperti halaman paspor. Ada cap progress, header perjalanan, dan chips yang terasa seperti stempel atau tiket.',
              ),
              const SizedBox(height: 16),
              const _ConceptCard(
                title: 'C. Mini Character Stage',
                subtitle: 'Raccoo jadi pusat pertunjukan.',
                badge: 'Paling ekspresif',
                color: _accentGreen,
                shadowColor: _accentGreenShadow,
                strengths: [
                  'Video Raccoo menjadi hero utama.',
                  'Cocok jika karakter ingin jadi pusat pengalaman.',
                  'Terasa hidup dan teatrikal.',
                ],
                layoutNotes:
                    'Area video membesar seperti panggung mini, lalu dialog dan contoh situasi turun sebagai panel pendukung.',
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                eyebrow: 'Design Tokens',
                title: 'Token Untuk Feel Cards',
                description:
                    'Token ini cukup spesifik untuk kebutuhan layar ini sehingga nanti implementasinya tidak liar.',
              ),
              const SizedBox(height: 12),
              const _TokenBoard(),
              const SizedBox(height: 24),
              const _SectionTitle(
                eyebrow: 'Component Stack',
                title: 'Komponen Kunci yang Perlu Diputuskan',
                description:
                    'Area ini memecah screen menjadi blok-blok yang akan benar-benar kita bangun.',
              ),
              const SizedBox(height: 12),
              const _DecisionGrid(),
              const SizedBox(height: 24),
              const _SectionTitle(
                eyebrow: 'Preview Flow',
                title: 'Flow Yang Saya Sarankan',
                description:
                    'Ini bukan mockup final, tapi urutan konten yang menurut saya paling sehat untuk dipakai.',
              ),
              const SizedBox(height: 12),
              const _FlowPreview(),
              const SizedBox(height: 24),
              const _SectionTitle(
                eyebrow: 'Decision Starter',
                title: 'Pilih Dari Sini',
                description:
                    'Kalau mau cepat, tentukan tiga hal ini dulu: arah konsep, bentuk progress, dan gaya content card.',
              ),
              const SizedBox(height: 12),
              const _ChoiceChecklist(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: FeelCardsDesignSystemScreen._brandShadow,
                  offset: Offset(3, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: FeelCardsDesignSystemScreen._text,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Feel Cards Design System',
            style: GoogleFonts.baloo2(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: FeelCardsDesignSystemScreen._text,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FeelCardsDesignSystemScreen._surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FeelCardsDesignSystemScreen._brandShadow,
            offset: Offset(4, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: FeelCardsDesignSystemScreen._brand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Decision Board',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FeelCardsDesignSystemScreen._brandShadow,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Halaman ini dipakai untuk mengunci gaya visual Raccoo Feel Cards sebelum kita rombak UI final.',
            style: GoogleFonts.baloo2(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: FeelCardsDesignSystemScreen._text,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Fokus utama: jelas untuk anak, terasa tactile, dan punya identitas yang lebih khas daripada flashcard standar.',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              height: 1.55,
              color: FeelCardsDesignSystemScreen._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FeelCardsDesignSystemScreen._brandShadow,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: FeelCardsDesignSystemScreen._text,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            height: 1.55,
            color: FeelCardsDesignSystemScreen._muted,
          ),
        ),
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final String title;
  final Color color;
  final Color shadowColor;
  final List<String> bullets;

  const _DecisionCard({
    required this.title,
    required this.color,
    required this.shadowColor,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: shadowColor, offset: const Offset(4, 7), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.baloo2(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.star_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ConceptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final Color shadowColor;
  final List<String> strengths;
  final String layoutNotes;

  const _ConceptCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.shadowColor,
    required this.strengths,
    required this.layoutNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.85),
            offset: const Offset(4, 7),
            blurRadius: 0,
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.22), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: FeelCardsDesignSystemScreen._text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: shadowColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.5,
              color: FeelCardsDesignSystemScreen._muted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kekuatan utama',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: shadowColor,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                for (final strength in strengths)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 7),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strength,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              height: 1.45,
                              color: FeelCardsDesignSystemScreen._text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            layoutNotes,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.55,
              color: FeelCardsDesignSystemScreen._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenBoard extends StatelessWidget {
  const _TokenBoard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FeelCardsDesignSystemScreen._brandShadow,
            offset: Offset(4, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TokenHeader(title: 'Warna inti'),
          SizedBox(height: 12),
          _ColorStrip(),
          SizedBox(height: 18),
          _TokenHeader(title: 'Tipografi'),
          SizedBox(height: 12),
          _TypeSample(
            title: 'Baloo 2 / 28 / 800',
            body: 'Dipakai untuk title emosi, title screen, dan CTA utama.',
          ),
          SizedBox(height: 10),
          _TypeSample(
            title: 'DM Sans / 16 / 400-700',
            body: 'Dipakai untuk penjelasan, hint, chips, dan detail situasi.',
          ),
          SizedBox(height: 18),
          _TokenHeader(title: 'Ritme layout'),
          SizedBox(height: 12),
          _TypeSample(
            title: 'Padding layar 24',
            body: 'Kartu utama mendominasi layar. Komponen lain hanya mendukung.',
          ),
          SizedBox(height: 10),
          _TypeSample(
            title: 'Radius 20-24',
            body: 'Semua surface utama terasa lembut dan aman untuk produk anak.',
          ),
          SizedBox(height: 10),
          _TypeSample(
            title: 'Shadow offset keras',
            body: 'Tidak blur lembek. Tetap hard shadow agar tactile dan toy-like.',
          ),
        ],
      ),
    );
  }
}

class _TokenHeader extends StatelessWidget {
  final String title;

  const _TokenHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.baloo2(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: FeelCardsDesignSystemScreen._text,
      ),
    );
  }
}

class _ColorStrip extends StatelessWidget {
  const _ColorStrip();

  @override
  Widget build(BuildContext context) {
    const swatches = [
      ('Emotion', FeelCardsDesignSystemScreen._brand, FeelCardsDesignSystemScreen._brandShadow),
      ('Passport', FeelCardsDesignSystemScreen._accentBlue, FeelCardsDesignSystemScreen._accentBlueShadow),
      ('Character', FeelCardsDesignSystemScreen._accentGreen, FeelCardsDesignSystemScreen._accentGreenShadow),
      ('Reward', FeelCardsDesignSystemScreen._accentGold, Color(0xFFC8A000)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: swatches
          .map(
            (swatch) => Container(
              width: 148,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: swatch.$2,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: swatch.$3.withValues(alpha: 0.9),
                    offset: const Offset(3, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    swatch.$1,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TypeSample extends StatelessWidget {
  final String title;
  final String body;

  const _TypeSample({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FeelCardsDesignSystemScreen._bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FeelCardsDesignSystemScreen._text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.55,
              color: FeelCardsDesignSystemScreen._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionGrid extends StatelessWidget {
  const _DecisionGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Progress',
        'Gunakan badge atau stamp, bukan dot generik, supaya anak merasa sedang menyelesaikan koleksi.'
      ),
      (
        'Card Front',
        'Front card harus punya teaser visual. Jangan kosong dan jangan hanya icon tanya.'
      ),
      (
        'Card Back',
        'Konten pecah menjadi blok yang cepat discan: hero, label emosi, speech, dan contoh situasi.'
      ),
      (
        'Done Screen',
        'Akhir permainan harus terasa seperti selesai mengumpulkan sesuatu, bukan sekadar selesai slide terakhir.'
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: FeelCardsDesignSystemScreen._brandShadow,
                      offset: Offset(3, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: GoogleFonts.baloo2(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: FeelCardsDesignSystemScreen._text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.55,
                        color: FeelCardsDesignSystemScreen._muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FlowPreview extends StatelessWidget {
  const _FlowPreview();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        '1. Intro',
        'Raccoo menyapa, anak melihat 6 badge emosi, lalu menekan tombol mulai.'
      ),
      (
        '2. Card Front',
        'Halaman menunjukkan nomor kartu, teaser emosi, dan CTA buka kartu.'
      ),
      (
        '3. Card Back',
        'Video Raccoo tampil dulu, lalu title emosi, dialog, dan chips contoh situasi.'
      ),
      (
        '4. Progress Reward',
        'Setelah pindah kartu, satu badge progress berubah menjadi penuh atau tercap.'
      ),
      (
        '5. Done',
        'Semua badge emosi tampil sebagai koleksi lengkap dan anak mendapat penutup yang memuaskan.'
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FeelCardsDesignSystemScreen._brandShadow,
            offset: Offset(4, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: steps
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: FeelCardsDesignSystemScreen._brand,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        step.$1.split('.').first,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$1,
                            style: GoogleFonts.baloo2(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: FeelCardsDesignSystemScreen._text,
                            ),
                          ),
                          Text(
                            step.$2,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              height: 1.55,
                              color: FeelCardsDesignSystemScreen._muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ChoiceChecklist extends StatelessWidget {
  const _ChoiceChecklist();

  @override
  Widget build(BuildContext context) {
    const choices = [
      (
        'Arah konsep',
        'Toy Flashcard / Passport / Character Stage',
      ),
      (
        'Bentuk progress',
        'Dot biasa / badge emosi / stamp koleksi',
      ),
      (
        'Gaya back card',
        'Informational card / story page / character stage',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FeelCardsDesignSystemScreen._text,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FeelCardsDesignSystemScreen._brandShadow,
            offset: Offset(4, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: choices
            .map(
              (choice) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.$1,
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        choice.$2,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
