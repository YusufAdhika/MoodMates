import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';
import '../../services/storage_service.dart';

/// Onboarding screen — tampil sekali saat pertama kali buka aplikasi.
///
/// Alur:
///   1. Anak/orang tua masukkan nama anak
///   2. Orang tua buat PIN 4 digit
///   3. Lanjut ke HomeScreen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _onLanjut() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Masukkan nama anak dulu ya!');
      return;
    }
    if (name.length > 50) {
      setState(() => _errorMessage = 'Nama terlalu panjang.');
      return;
    }
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _errorMessage = 'PIN orang tua harus 4 angka.');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _errorMessage = 'Konfirmasi PIN belum cocok.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final progressProvider = context.read<ProgressProvider>();
    final storageService = context.read<StorageService>();

    try {
      await progressProvider.setChildName(name);
      await storageService.setPin(pin);
      if (!mounted) return;
      context.go('/');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mascot placeholder
                const Icon(
                  Icons.emoji_emotions,
                  size: 96,
                  color: Color(0xFFFFB347),
                ),
                const SizedBox(height: 24),

                // Judul
                const Text(
                  'Halo! 👋',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C4033),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Siapa nama kamu?',
                  style: TextStyle(fontSize: 22, color: Colors.brown),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.child_care, color: Color(0xFFFFB347)),
                          SizedBox(width: 8),
                          Text(
                            'Untuk Anak',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C4033),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 50,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.brown,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis namamu di sini...',
                          hintStyle: TextStyle(color: Colors.brown.shade200),
                          filled: true,
                          fillColor: const Color(0xFFFFF8E7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          counterText: '',
                        ),
                        onSubmitted: (_) => _onLanjut(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.brown),
                          SizedBox(width: 8),
                          Text(
                            'Untuk Orang Tua',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C4033),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PIN ini dipakai untuk membuka dashboard orang tua.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'PIN orang tua (4 angka)',
                          hintStyle: TextStyle(color: Colors.brown.shade200),
                          filled: true,
                          fillColor: const Color(0xFFFFF8E7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          counterText: '',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscurePin = !_obscurePin);
                            },
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPinController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        obscureText: _obscureConfirmPin,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Ulangi PIN orang tua',
                          hintStyle: TextStyle(color: Colors.brown.shade200),
                          filled: true,
                          fillColor: const Color(0xFFFFF8E7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          counterText: '',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPin = !_obscureConfirmPin;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPin
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _onLanjut(),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],

                const SizedBox(height: 24),

                // Tombol lanjut
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onLanjut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB347),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Mulai Bermain! 🎮',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info untuk orang tua
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setup ini cuma sekali. Nanti orang tua bisa masuk lewat Mode Orang Tua dengan PIN tadi.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
