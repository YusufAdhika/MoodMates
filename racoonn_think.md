# 🎯 Raccoo Think – Sistem Leveling

## 📌 Deskripsi
Raccoo Think adalah fitur pembelajaran sosial-emosional untuk anak usia TK.  
Anak melihat ilustrasi situasi sosial sehari-hari (misalnya: teman menangis, berbagi, bertengkar), lalu memilih 1 dari 2 respons (benar/salah).

Aplikasi memiliki bank soal dari 6 tema keterampilan sosial.

---

## 🎯 Tujuan
Membuat fitur leveling yang:
- Adaptif dan variatif
- Ramah anak usia dini
- Mendukung pembelajaran bertahap
- Menggunakan prinsip **Explicit SAFE (Sequenced, Active, Focused, Explicit)**

---

# 🔹 CORE SYSTEM (WAJIB ADA)

## 1. Struktur Level
- Level 1, Level 2, Level 3
- Setiap level terdiri dari **3 pertanyaan**
- Total 1 sesi = **9 pertanyaan**

---

## 2. Randomisasi
- Sistem mengacak tema dari 6 tema
- Sistem mengacak soal dari bank soal
- Setiap user mendapatkan kombinasi berbeda
- Tidak ada soal yang berulang dalam 1 sesi

---

## 3. Progression
- Level dimainkan berurutan
- Level berikutnya terbuka setelah level sebelumnya selesai
- Jika gagal → ulang level dengan soal berbeda

---

## 4. Scoring
- 1 jawaban benar = 1 poin
- Maksimum per level = 3 poin

### Evaluasi:
- 3 benar → lanjut
- 2 benar → boleh lanjut / opsional ulang
- 0–1 benar → wajib ulang

---

## 5. Feedback (PENTING)

### ✅ Jika jawaban BENAR:
- Berikan pujian sederhana
- Contoh:
  - "Hebat! Itu pilihan yang baik."
  - "Bagus! Kamu peduli dengan teman."

### ❗ Jika jawaban SALAH:
- **JANGAN menunjukkan jawaban benar**
- **JANGAN menyebut kata “salah”**
- Gunakan pendekatan reflektif

Contoh:
- "Hmm, coba lihat lagi ya 😊"
- "Menurut kamu, mana yang lebih baik?"
- "Yuk coba pilih lagi"

### Tujuan:
- Mendorong anak berpikir
- Menghindari rasa dihakimi
- Mendukung pembelajaran aktif

---

# 🟢 MVP (Minimum Viable Product)

Fitur wajib:

- Sistem leveling (Level 1–3)
- 3 soal per level
- Randomisasi soal sederhana
- Progress sederhana (1/3, 2/3, 3/3)
- Feedback:
  - Benar → pujian
  - Salah → reflektif (tanpa membenarkan langsung)
- Retry level jika gagal
- UI sederhana:
  - Gambar besar
  - 2 pilihan jawaban
  - Tombol besar dan jelas
- Tanpa sistem adaptif kompleks

---

# 🔵 NON-MVP (FUTURE IMPROVEMENT)

## 1. Adaptive Learning
- Tingkat kesulitan menyesuaikan performa anak

## 2. Smart Randomization
- Hindari soal yang sudah pernah muncul
- Prioritaskan soal baru

## 3. Progress Tracking
- Menyimpan:
  - skor
  - level terakhir
  - tema yang sudah dimainkan

## 4. Reward System Lanjutan
- Badge per tema
- Koleksi karakter
- Sistem bintang

## 5. Audio & Voice
- Narasi suara
- Feedback suara

## 6. Visual Feedback Interaktif
- Animasi benar/salah
- Karakter bereaksi

## 7. Parent/Teacher Dashboard
- Laporan perkembangan anak
- Insight keterampilan sosial

## 8. Dynamic Content
- Penambahan soal tanpa update besar

---

# 🧠 INTEGRASI EXPLICIT SAFE

## Explicit
Tampilkan tujuan pembelajaran di awal level  
Contoh:  
"Hari ini kita belajar membantu teman"

## Sequenced
Level 1 → Level 2 → Level 3 (mudah ke sulit)

## Active
Anak aktif memilih jawaban

## Focused
1 soal = 1 keterampilan sosial

## Safe
- Tidak menghakimi
- Tidak menyebut “salah”
- Mendorong eksplorasi

---

# 📦 FORMAT DATA SOAL
Tema: [nama tema]
Level: [1 / 2 / 3]
Situasi: [deskripsi]
Pilihan Benar: [deskripsi]
Pilihan Salah: [deskripsi]

---

# 📌 OUTPUT YANG DIHARAPKAN

- Flow sistem leveling
- Logika randomisasi soal
- Logika scoring & retry
- Contoh 1 sesi (9 soal)
- Rekomendasi UI/UX sederhana
- Pembagian MVP vs Non-MVP

---

# ✅ KRITERIA SUKSES

- Ramah anak usia dini
- Tidak membuat anak merasa “salah”
- Variatif antar user
- Sederhana & visual
- Mendukung pembelajaran sosial bertahap