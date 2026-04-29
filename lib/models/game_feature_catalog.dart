import 'package:flutter/material.dart';

import 'game_progress.dart';

class GameFeatureMeta {
  final String id;
  final String title;
  final String summary;
  final String parentTip;
  final String trackingNote;
  final IconData icon;
  final Color color;

  const GameFeatureMeta({
    required this.id,
    required this.title,
    required this.summary,
    required this.parentTip,
    required this.trackingNote,
    required this.icon,
    required this.color,
  });
}

const List<GameFeatureMeta> activeGameFeatures = [
  GameFeatureMeta(
    id: GameProgress.gameFeelCards,
    title: 'Raccoo Feel Cards',
    summary: 'Mengenal emosi, cerita singkat, dan contoh situasi sehari-hari.',
    parentTip:
        'Dampingi anak menyebut nama emosi, lalu tanyakan kapan anak pernah merasakan emosi itu.',
    trackingNote:
        'Satu penyelesaian rangkaian kartu tercatat sebagai satu data bermain.',
    icon: Icons.style_rounded,
    color: Color(0xFFFF9A3C),
  ),
  GameFeatureMeta(
    id: GameProgress.gameExpressionMirroring,
    title: 'Raccoo Mirror',
    summary: 'Meniru ekspresi wajah dan belajar mengenali bentuk emosi.',
    parentTip:
        'Beri contoh ekspresi bersama anak dan bantu anak fokus pada mata, mulut, dan alis.',
    trackingNote:
        'Data tersimpan dari respons ekspresi yang berhasil diselesaikan anak.',
    icon: Icons.camera_front_rounded,
    color: Color(0xFF4C8BF5),
  ),
  GameFeatureMeta(
    id: GameProgress.gameSocialSituations,
    title: 'Raccoo Think',
    summary: 'Memilih respons sosial yang tepat dari situasi bergambar.',
    parentTip:
        'Sesudah bermain, ajak anak menjelaskan alasan memilih jawaban, lalu cocokkan dengan kategori hasil sesinya.',
    trackingNote:
        'Penilaian sesi level memakai 6 soal. Skor sesi = jumlah benar/6 x 100. Kategori: 5-6 Mahir, 3-4 Berkembang, 1-2 Mulai Tumbuh, 0 Perlu Bimbingan.',
    icon: Icons.groups_rounded,
    color: Color(0xFF4CAF6E),
  ),
];

GameFeatureMeta featureMetaFor(String gameId) {
  for (final feature in activeGameFeatures) {
    if (feature.id == gameId) return feature;
  }

  return const GameFeatureMeta(
    id: 'unknown',
    title: 'Fitur Lain',
    summary: 'Data lama atau fitur yang tidak tampil di menu utama.',
    parentTip: 'Tidak ada panduan khusus.',
    trackingNote:
        'Data ini tidak termasuk tiga fitur utama yang aktif saat ini.',
    icon: Icons.extension_rounded,
    color: Colors.grey,
  );
}

int totalStarsForActiveGames(GameProgress progress) {
  return activeGameFeatures.fold(
    0,
    (total, feature) => total + progress.starsFor(feature.id),
  );
}

int totalRecordsForActiveGames(GameProgress progress) {
  return activeGameFeatures.fold(
    0,
    (total, feature) => total + (progress.playCounts[feature.id] ?? 0),
  );
}

int totalCorrectForActiveGames(GameProgress progress) {
  return activeGameFeatures.fold(
    0,
    (total, feature) => total + (progress.correctCounts[feature.id] ?? 0),
  );
}
