import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';

// ─── Green Design Tokens ──────────────────────────────────────────────────────
const _brandGreen  = Color(0xFF4CAF6E);
const _brandShadow = Color(0xFF2A7A48);
const _bg          = Color(0xFFEDFFF3);
const _textColor   = Color(0xFF1A3A2A);
const _mutedText   = Color(0xFF557A65);

/// PIN entry screen guarding access to the Parent Dashboard.
///
/// If no PIN is set yet, the first entry sets the PIN.
/// 5-tap easter egg on the title resets a forgotten PIN.
///
/// Children mashing numbers: safe — only activates on exact 4-digit match.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _enteredPin = '';
  bool _isSettingPin = false;
  String _confirmPin = '';
  bool _isConfirming = false;
  int _titleTapCount = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _isSettingPin = !storage.hasPin;
  }

  void _onDigitTap(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = '';
    });
    if (_enteredPin.length == 4) {
      _onPinComplete();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
  }

  Future<void> _onPinComplete() async {
    final storage = context.read<StorageService>();

    if (_isSettingPin) {
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _confirmPin) {
          await storage.setPin(_enteredPin);
          if (mounted) context.go('/parent-dashboard');
        } else {
          setState(() {
            _enteredPin = '';
            _confirmPin = '';
            _isConfirming = false;
            _errorMessage = 'PIN tidak cocok. Coba lagi.';
          });
        }
      }
    } else {
      if (storage.validatePin(_enteredPin)) {
        if (mounted) context.go('/parent-dashboard');
      } else {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'PIN salah. Coba lagi.';
        });
      }
    }
  }

  /// 5-tap easter egg on the lock icon to reset a forgotten PIN.
  void _onTitleTap() {
    _titleTapCount++;
    if (_titleTapCount >= 5) {
      _titleTapCount = 0;
      _showResetPinDialog();
    }
  }

  void _showResetPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text('PIN akan dihapus. Anda perlu membuat PIN baru.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _mutedText),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final storage = context.read<StorageService>();
              await storage.clearPin();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {
                _isSettingPin = true;
                _enteredPin = '';
                _confirmPin = '';
                _isConfirming = false;
                _errorMessage = '';
              });
            },
            style: TextButton.styleFrom(foregroundColor: _brandGreen),
            child: const Text('Ya, reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String prompt;
    String subtitle;
    if (_isSettingPin) {
      prompt = _isConfirming ? 'Konfirmasi PIN baru' : 'Buat PIN orang tua';
      subtitle = _isConfirming
          ? 'Masukkan lagi 4 angka yang sama.'
          : 'Pakai 4 angka yang mudah diingat orang tua.';
    } else {
      prompt = 'Masukkan PIN orang tua';
      subtitle = 'PIN ini membuka dashboard dan data perkembangan anak.';
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _brandShadow),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 5-tap secret reset
            GestureDetector(
              onTap: _onTitleTap,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _brandGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _brandGreen.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 48, color: _brandGreen),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              prompt,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _mutedText, fontSize: 14),
              ),
            ),
            const SizedBox(height: 28),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: filled ? 22 : 18,
                  height: filled ? 22 : 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? _brandGreen : Colors.green.shade100,
                    border: Border.all(
                      color: filled
                          ? _brandShadow
                          : _brandGreen.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Number pad
            _NumberPad(onDigit: _onDigitTap, onDelete: _onDelete),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumberPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((digit) {
                if (digit.isEmpty) return const SizedBox(width: 72);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _PadButton(
                    label: digit == 'del' ? '⌫' : digit,
                    onTap: () =>
                        digit == 'del' ? onDelete() : onDigit(digit),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ),
      ),
    );
  }
}
