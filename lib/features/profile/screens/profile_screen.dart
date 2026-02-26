import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_models.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/models/marketplace_models.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

final _fmt = NumberFormat('#,##0', 'ru_RU');

// Profile provider using the new /profile endpoint
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await api.get('/profile');
  return res.data;
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final bookings = ref.watch(myBookingsProvider);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text('Войдите в аккаунт', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('Войти'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (_, __) => _buildBasicUserInfo(auth.user),
              data: (data) {
                final userInfo = data['userInfo'];
                if (_firstNameCtrl.text.isEmpty && userInfo != null) {
                  _firstNameCtrl.text = userInfo['firstName'] ?? '';
                  _lastNameCtrl.text = userInfo['lastName'] ?? '';
                  _middleNameCtrl.text = userInfo['middleName'] ?? '';
                  _emailCtrl.text = userInfo['email'] ?? '';
                }

                return Column(
                  children: [
                    _buildUserCard(userInfo),
                    const SizedBox(height: 16),
                    // Apartments
                    if (data['apartments'] != null && (data['apartments'] as List).isNotEmpty)
                      _buildApartmentsSection(
                        (data['apartments'] as List)
                            .map((e) => UserApartmentInfo.fromJson(e))
                            .toList(),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Bookings
            const Text('Мои бронирования',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            bookings.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (_, __) => const Text('Ошибка загрузки', style: TextStyle(color: AppTheme.error)),
              data: (list) => list.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Нет бронирований', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    )
                  : Column(
                      children: list.map((b) => _bookingCard(b)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicUserInfo(UserInfo? user) {
    if (user == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('${user.lastName} ${user.firstName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.phone, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic>? userInfo) {
    if (userInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (userInfo['firstName'] ?? '?')[0],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userInfo['fullName'] ?? '',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                    Text(userInfo['phone'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_editing ? Icons.close : Icons.edit, color: AppTheme.primary, size: 20),
                onPressed: () => setState(() => _editing = !_editing),
              ),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Фамилия'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _middleNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Отчество'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  try {
                    await api.put('/profile', data: {
                      'firstName': _firstNameCtrl.text,
                      'lastName': _lastNameCtrl.text,
                      'middleName': _middleNameCtrl.text,
                      'email': _emailCtrl.text,
                    });
                    setState(() => _editing = false);
                    ref.invalidate(profileProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ошибка сохранения'), backgroundColor: AppTheme.error),
                      );
                    }
                  } finally {
                    setState(() => _saving = false);
                  }
                },
                child: _saving
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Сохранить'),
              ),
            ),
          ],
          if (userInfo['email'] != null && !_editing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Text(userInfo['email'], style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApartmentsSection(List<UserApartmentInfo> apartments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Мои квартиры', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...apartments.map((apt) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Кв. №${apt.number}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('${_fmt.format(apt.totalPrice)} сом',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
              if (apt.address != null) ...[
                const SizedBox(height: 4),
                Text(apt.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              // Payment progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Оплачено: ${_fmt.format(apt.paidAmount)} сом',
                    style: const TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('Осталось: ${_fmt.format(apt.remainingAmount)} сом',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: apt.totalPrice > 0 ? apt.paidAmount / apt.totalPrice : 0,
                  backgroundColor: AppTheme.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _bookingCard(Booking b) {
    Color statusColor;
    switch (b.status) {
      case 'ACTIVE':
        statusColor = AppTheme.success;
        break;
      case 'CONVERTED':
        statusColor = AppTheme.info;
        break;
      default:
        statusColor = AppTheme.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Кв. №${b.apartmentNumber ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (b.buildingName != null)
                Text(b.buildingName!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text(b.createdAt.isNotEmpty ? b.createdAt.substring(0, 10) : '',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(b.statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
