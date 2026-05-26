import 'package:flutter/material.dart';
import '../../core/security/auth_service.dart';
import '../../core/theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  late AnimationController _shake;

  @override
  void initState() {
    super.initState();
    // Shake animation for failed auth
    _shake = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350));
    // Auto-trigger fingerprint prompt on load
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _auth());
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _auth() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await AuthService.instance.authenticate();

    if (!mounted) return;
    if (result == AuthResult.success) {
      widget.onUnlocked(); // tell AppGate to unlock
    } else {
      setState(() {
        _busy = false;
        _error = AuthService.instance.label(result);
      });
      _shake.forward(from: 0); // shake on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C6FCD),
                        Color(0xFF5A4FB0)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: .5),
                        blurRadius: 30,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text('₹',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                const Text('Artha',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const SizedBox(height: 6),
                const Text('Your private finance assistant',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14)),

                const SizedBox(height: 64),

                // Fingerprint button — shakes on failed auth
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) {
                    // Create left-right shake movement
                    final offset = _shake.isAnimating
                        ? 12 *
                            ((_shake.value * 6).round() % 2 == 0
                                ? 1.0
                                : -1.0)
                        : 0.0;
                    return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child);
                  },
                  child: GestureDetector(
                    onTap: _auth,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _busy
                            ? AppColors.purple.withValues(alpha: 0.4)
                            : AppColors.purple,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.purple.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Icon(Icons.fingerprint,
                              color: Colors.white, size: 38),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  _busy ? 'Authenticating…' : 'Tap to unlock',
                  style: TextStyle(
                    color: _error != null
                        ? AppColors.expense
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: _auth,
                      child: const Text('Try Again')),
                ],

                const SizedBox(height: 48),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 11, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text('All data on this device only',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}