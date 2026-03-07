import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart'; // profileProvider
import '../../marketplace/providers/marketplace_provider.dart'; // myBookingsProvider
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo area
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.apartment_rounded, size: 40, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Text('Добро пожаловать',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text('Войдите для просмотра недвижимости',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Phone
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                  hintText: '+996 XXX XXX XXX',
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 14)),
                ),
              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: auth.isLoading ? null : () async {
                  final ok = await ref.read(authProvider.notifier).login(
                    _phoneController.text.trim(),
                    _passwordController.text,
                  );
                  if (ok && context.mounted) {
                    // Invalidate providers so profile re-fetches with new token
                    ref.invalidate(profileProvider);
                    ref.invalidate(myBookingsProvider);
                    Navigator.of(context).pop();
                  }
                },
                child: auth.isLoading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Войти'),
              ),
              const SizedBox(height: 16),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Нет аккаунта? ', style: TextStyle(color: AppTheme.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                    child: const Text('Регистрация', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
