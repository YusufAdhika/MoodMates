# Dokumentasi Lengkap Proyek: Moodmates

## 1. Pendahuluan
**Moodmates** adalah platform edukasi interaktif berbasis mobile yang dirancang khusus untuk anak usia dini (4-6 tahun). Aplikasi ini bertujuan membangun literasi emosi dan kecerdasan sosial melalui metode bermain berbasis *Social Emotional Learning* (SEL).

---

## 2. Struktur Arsitektur
Proyek ini mengadopsi pola **Layered Architecture**:
*   **View Layer (`screens/`):** UI reaktif berbasis Flutter.
*   **Business Logic Layer (`providers/`):** State management (Progress, Auth, Audio).
*   **Service Layer (`services/`):** Wrapper API (ML Kit, Camera, Storage).
*   **Data Layer (`models/`):** Struktur data type-safe.

---

## 3. Alur Sistem (Flowchart)

Berikut adalah diagram alur mendalam yang mencakup logika permainan dan validasi input:

```mermaid
graph TD
    %% Node Definitions
    Start([Mulai Aplikasi]) --> CheckProfile{Profil Ada?}
    
    subgraph Pengaturan_Awal [Fase Setup]
        CheckProfile -- Tidak --> CreateProfile[Input Nama & Karakter]
        CreateProfile --> SaveProfile[Simpan ke Local Storage]
    end
    
    subgraph Dashboard_Utama [Pusat Navigasi]
        CheckProfile -- Ya --> Home[Dashboard Menu]
        SaveProfile --> Home
        Home --> ModulEmosi[Modul: Kenali Emosi]
        Home --> ModulCermin[Modul: Cermin Ekspresi]
        Home --> ModulSosial[Modul: Situasi Sosial]
        Home --> ParentGate[Area Orang Tua]
    end

    subgraph Logika_Permainan [Game Loop]
        ModulCermin --> PlayAudio[Putar Instruksi Suara]
        PlayAudio --> StartCamera[Aktifkan Kamera Depan]
        StartCamera --> MLProcess[Proses Frame via ML Kit]
        
        MLProcess --> DetectFace{Wajah Terdeteksi?}
        DetectFace -- Tidak --> PromptUser[Tampilkan Panduan Posisi]
        PromptUser --> MLProcess
        
        DetectFace -- Ya --> CompareEmotion{Ekspresi Sesuai?}
        CompareEmotion -- Ya --> Success[Efek Konfeti + Audio Hebat]
        CompareEmotion -- Tidak --> WaitInput[Tunggu Perubahan Ekspresi]
        WaitInput --> MLProcess
    end

    subgraph Finalisasi [Pencatatan Skor]
        Success --> UpdateScore[Update ProgressProvider]
        UpdateScore --> PersistData[Simpan ke Disk]
        PersistData --> Home
    end

    subgraph Keamanan [Parental Control]
        ParentGate --> PinInput[Input PIN 4 Digit]
        PinInput --> VerifyPin{PIN Benar?}
        VerifyPin -- Ya --> ParentDash[Dashboard Analitik]
        VerifyPin -- Tidak --> PinInput
    end

    %% Styling
    style Start fill:#f9f,stroke:#333,stroke-width:2px
    style Success fill:#dfd,stroke:#2a2,stroke-width:2px
    style Home fill:#bbf,stroke:#333
```

---

## 4. Alur Kerja Teknis (Sequence Diagram)

Diagram ini menjelaskan interaksi antar komponen saat proses deteksi ekspresi:

```mermaid
sequenceDiagram
    autonumber
    participant U as User (Anak)
    participant UI as Screen (Flutter)
    participant P as ProgressProvider
    participant S as MLService
    participant ML as ML Kit Engine

    U->>UI: Klik Mulai Tantangan
    UI->>S: Request Kamera & ML Detection
    S->>ML: Start Face Detection
    loop Real-time Analysis
        ML-->>S: Hasil Probabilitas (Happy: 0.9)
        S->>P: Kirim Data Ekspresi
        P->>P: Validasi terhadap Target
    end
    Note over P: Jika Happy > 0.75
    P->>UI: Trigger UI Success
    UI->>U: Tampilkan Animasi & Suara
    P->>S: Stop Detection
```

---

## 5. Detail Teknis Komponen
*   **MLService:** Menggunakan `google_mlkit_face_detection` untuk mendapatkan `smilingProbability` dan `eyeOpenProbability`.
*   **AudioService:** Mengatur antrean audio agar instruksi tidak bertabrakan dengan efek suara pujian.
*   **StorageService:** Menggunakan `shared_preferences` untuk persistensi data ringan secara offline-first.

---
*Dokumentasi Moodmates v1.1.0*
