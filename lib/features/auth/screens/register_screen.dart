import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/auth_models.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// RegisterScreen — 3-step registration flow matching web frontend:
/// Step 1: Phone → POST /auth/otp/send → get token
/// Step 2: OTP code → POST /auth/otp/verify → verify
/// Step 3: Details → POST /auth/register → create account + get JWT
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Steps: 0=phone, 1=otp, 2=details
  int _step = 0;
  bool _loading = false;
  String? _error;

  // Step 1: Phone
  final _phoneCtrl = TextEditingController();

  // Step 2: OTP
  String _otpToken = '';
  final _otpCtrl = TextEditingController();

  // Step 3: Details
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // Step 1: Send OTP
  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Введите номер телефона');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await api.post('/auth/otp/send', data: {
        'phone': _phoneCtrl.text.trim(),
      });
      _otpToken = res.data['token'] ?? '';
      setState(() { _step = 1; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = 'Ошибка отправки SMS. Проверьте номер.'; });
    }
  }

  // Step 2: Verify OTP
  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Введите код из SMS');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await api.post('/auth/otp/verify', data: {
        'token': _otpToken,
        'code': _otpCtrl.text.trim(),
      });
      if (res.data['verified'] == true) {
        setState(() { _step = 2; _loading = false; });
      } else {
        setState(() { _loading = false; _error = 'Неверный код. Попробуйте ещё раз.'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Ошибка проверки кода'; });
    }
  }

  // Step 3: Register
  Future<void> _register() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Заполните обязательные поля');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Пароль минимум 6 символов');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final ok = await ref.read(authProvider.notifier).register(
      RegisterRequest(
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim().isNotEmpty ? _middleNameCtrl.text.trim() : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      ),
    );
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = ref.read(authProvider).error ?? 'Ошибка регистрации');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Создайте аккаунт',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(
                _step == 0 ? 'Введите номер телефона'
                    : _step == 1 ? 'Введите код из SMS'
                    : 'Заполните данные',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Progress bar
              _buildProgress(),
              const SizedBox(height: 24),

              // Error
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 14)),
                ),

              // Steps
              if (_step == 0) _buildPhoneStep(),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildDetailsStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        Expanded(child: Container(
          height: 4, decoration: BoxDecoration(
            color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(width: 4),
        Expanded(child: Container(
          height: 4, decoration: BoxDecoration(
            color: _step >= 1 ? AppTheme.primary : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(width: 4),
        Expanded(child: Container(
          height: 4, decoration: BoxDecoration(
            color: _step >= 2 ? AppTheme.primary : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(2)),
        )),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Номер телефона',
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
            hintText: '+996 XXX XXX XXX',
          ),
          onSubmitted: (_) => _sendOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            child: _loading ? _loadingIndicator() : const Text('Получить код'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Text('Код отправлен на ${_phoneCtrl.text}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(
            hintText: '• • • •',
            counterText: '',
          ),
          maxLength: 6,
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            child: _loading ? _loadingIndicator() : const Text('Подтвердить'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : () async {
            setState(() => _otpCtrl.clear());
            await _sendOtp();
          },
          child: const Text('Отправить код повторно', style: TextStyle(color: AppTheme.textMuted)),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      children: [
        TextField(
          controller: _lastNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Фамилия *',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _firstNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Имя *',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _middleNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Отчество',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Пароль *',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
            hintText: 'Минимум 6 символов',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _register,
            child: _loading ? _loadingIndicator() : const Text('Зарегистрироваться'),
          ),
        ),
      ],
    );
  }

  Widget _loadingIndicator() => const SizedBox(
    width: 24, height: 24,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
  );
}
