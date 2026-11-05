import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';
import '../data/retail_repository.dart';
import '../state/retail_providers.dart';
import '../state/session_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../widgets/shared/pin_pad.dart';

/// PIN sign-in. The server checks the PIN; the app never compares it itself.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _pin_length = 4;

  String _pin = '';
  String? _error_text;
  bool _is_checking = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _add_digit(String digit) {
    if (_is_checking || _pin.length >= _pin_length) return;
    setState(() {
      _pin += digit;
      _error_text = null;
    });
    if (_pin.length == _pin_length) _try_login(_pin);
  }

  void _delete() {
    if (_is_checking || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error_text = null;
    });
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _error_text = message;
      _pin = '';
    });
    _shake.forward(from: 0);
  }

  Future<void> _try_login(String pin) async {
    setState(() {
      _is_checking = true;
      _error_text = null;
    });
    try {
      final user = await ref.read(retail_repository_provider).sign_in(pin);
      if (!mounted) return;
      ref.read(current_user_provider.notifier).state = user;
    } on WrongPin {
      if (!mounted) return;
      _fail('That PIN is not right');
    } catch (_) {
      if (!mounted) return;
      _fail('Could not reach the shop server. Check the connection.');
    } finally {
      if (mounted) setState(() => _is_checking = false);
    }
  }

  /// A hardware keyboard works too (web and desktop).
  KeyEventResult _on_key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final typed = event.character;
    if (typed != null && typed.length == 1 && '0123456789'.contains(typed)) {
      _add_digit(typed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _delete();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _on_key,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.line),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F2563EB),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Text('🧺', style: TextStyle(fontSize: 46)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Fresh Preorder',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(shop_name,
                      style: TextStyle(color: AppColors.ink_soft, fontSize: 14)),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final dx = math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);
                      return Transform.translate(offset: Offset(dx, 0), child: child);
                    },
                    child: PinDots(
                      length: _pin_length,
                      filled: _pin.length,
                      has_error: _error_text != null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: _is_checking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _error_text ?? 'Enter your 4-digit PIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    _error_text == null ? FontWeight.w400 : FontWeight.w600,
                                color: _error_text == null
                                    ? AppColors.ink_soft
                                    : AppColors.danger,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PinPad(
                    on_digit: _add_digit,
                    on_delete: _delete,
                    enabled: !_is_checking,
                  ),
                  if (use_demo_data) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: soft_tint(AppColors.accent),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: const Text(
                        'Demo data  ·  retailer 1234  ·  customers 1111, 2222',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
