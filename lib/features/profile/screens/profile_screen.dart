import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_models.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/models/marketplace_models.dart';
import '../models/contract_models.dart';
import '../providers/contract_provider.dart';
import '../providers/notification_provider.dart';
import 'contract_detail_screen.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/sse_service.dart';
import '../../../core/theme/app_theme.dart';

final _fmt = NumberFormat('#,##0', 'ru_RU');

// Profile provider using the new /profile endpoint
final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final res = await api.get('/profile');
    return res.data;
  } catch (_) {
    return null;
  }
});

// Payment schedule provider
final myPaymentScheduleProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await api.get('/profile/payment-schedule');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  // Expansion state
  bool _apartmentsExpanded = true;
  bool _contractsExpanded = false;
  bool _bookingsExpanded = false;
  bool _paymentsExpanded = false;
  bool _sseStarted = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(profileProvider);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(myContractsProvider);
      ref.invalidate(myPaymentScheduleProvider);
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final bookings = ref.watch(myBookingsProvider);

    // SSE уведомления теперь обрабатываются на уровне MainShell (app.dart)

    final contracts = ref.watch(myContractsProvider);
    final paymentSchedule = ref.watch(myPaymentScheduleProvider);

    // Refresh payments on SSE payment_recorded event
    ref.listen<NotificationState>(notificationProvider, (prev, next) {
      if (next.eventType == 'payment_recorded' && next.timestamp != prev?.timestamp) {
        ref.invalidate(myPaymentScheduleProvider);
        ref.invalidate(profileProvider);
      }
    });

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
                onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed('/login'),
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
              sseService.disconnect();
              _sseStarted = false;
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
                if (data == null) return _buildBasicUserInfo(auth.user);
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
                    // Apartments Section
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

            const SizedBox(height: 8),

            // Contracts Section (expandable)
            _buildContractsSection(contracts),

            const SizedBox(height: 8),

            // Bookings Section (expandable)
            _buildBookingsSection(bookings),

            const SizedBox(height: 8),

            // Payments Section (expandable)
            _buildPaymentsSection(paymentSchedule),
          ],
        ),
      ),
    );
  }

  // ── User Info Widgets ──

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

  // ── Expandable Section Builder ──

  Widget _buildExpandableSection({
    required String icon,
    required String title,
    required int count,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.chevron_right, color: AppTheme.primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // ── Apartments Section (Bought vs Installment) ──

  Widget _buildApartmentsSection(List<UserApartmentInfo> apartments) {
    final bought = apartments.where((a) => a.remainingAmount <= 0).toList();
    final installment = apartments.where((a) => a.remainingAmount > 0).toList();

    return _buildExpandableSection(
      icon: '🏠',
      title: 'Мои квартиры',
      count: apartments.length,
      expanded: _apartmentsExpanded,
      onToggle: () => setState(() => _apartmentsExpanded = !_apartmentsExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Купленные
          if (bought.isNotEmpty) ...[
            _subHeader('✅', 'Купленные', const Color(0xFF4ECB71)),
            ...bought.map(_boughtApartmentCard),
          ],
          // В рассрочку
          if (installment.isNotEmpty) ...[
            _subHeader('⏳', 'В рассрочку', const Color(0xFFFFB347)),
            ...installment.map(_installmentApartmentCard),
          ],
        ],
      ),
    );
  }

  Widget _subHeader(String icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6, left: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _boughtApartmentCard(UserApartmentInfo apt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Кв. №${apt.number}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${_fmt.format(apt.totalPrice)} сом',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          if (apt.address != null) ...[
            const SizedBox(height: 4),
            Text(apt.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: Color(0xFF4ECB71)),
              SizedBox(width: 4),
              Text('Оплачено полностью',
                style: TextStyle(color: Color(0xFF4ECB71), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 1.0,
              backgroundColor: Color(0xFF333355),
              valueColor: AlwaysStoppedAnimation(Color(0xFF4ECB71)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _installmentApartmentCard(UserApartmentInfo apt) {
    final progress = apt.totalPrice > 0 ? apt.paidAmount / apt.totalPrice : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Кв. №${apt.number}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${_fmt.format(apt.totalPrice)} сом',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          if (apt.address != null) ...[
            const SizedBox(height: 4),
            Text(apt.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('Оплачено: ${_fmt.format(apt.paidAmount)} сом',
                style: const TextStyle(color: Color(0xFF4ECB71), fontSize: 12, fontWeight: FontWeight.w500)),
              Text('Осталось: ${_fmt.format(apt.remainingAmount)} сом',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF333355),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4ECB71)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contracts Section ──

  Widget _buildContractsSection(AsyncValue<List<ContractResponse>> contracts) {
    return contracts.when(
      loading: () => _buildExpandableSection(
        icon: '📄', title: 'Мои договоры', count: 0,
        expanded: _contractsExpanded,
        onToggle: () => setState(() => _contractsExpanded = !_contractsExpanded),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (_, __) => _buildExpandableSection(
        icon: '📄', title: 'Мои договоры', count: 0,
        expanded: _contractsExpanded,
        onToggle: () => setState(() => _contractsExpanded = !_contractsExpanded),
        child: const Text('Ошибка загрузки', style: TextStyle(color: AppTheme.error)),
      ),
      data: (list) {
        // Сортируем: новые первые
        final sorted = List<ContractResponse>.from(list)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _buildExpandableSection(
          icon: '📄',
          title: 'Мои договоры',
          count: sorted.length,
          expanded: _contractsExpanded,
          onToggle: () => setState(() => _contractsExpanded = !_contractsExpanded),
          child: sorted.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Нет договоров', style: TextStyle(color: AppTheme.textMuted))),
                )
              : Column(children: sorted.map(_contractCard).toList()),
        );
      },
    );
  }

  Widget _contractCard(ContractResponse c) {
    Color statusColor;
    switch (c.status) {
      case 'PENDING_BUYER_SIGNATURE': statusColor = Colors.yellow; break;
      case 'PENDING_COMPANY_SIGNATURE': statusColor = Colors.orange; break;
      case 'SIGNED': statusColor = const Color(0xFF4ECB71); break;
      case 'IN_PAYMENT': statusColor = const Color(0xFF6495ED); break;
      default: statusColor = AppTheme.textMuted;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ContractDetailScreen(contract: c)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: c.needsBuyerSignature
                ? Colors.yellow.withOpacity(0.3)
                : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.contractNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Кв. №${c.apartmentNumber ?? c.apartmentId}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  Text('${_fmt.format(c.totalPrice)} сом',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                  if (c.needsBuyerSignature)
                    const Text('⚠️ Требуется ваша подпись',
                      style: TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(c.statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                const SizedBox(height: 4),
                if (c.createdAt.isNotEmpty)
                  Text(c.createdAt.substring(0, 10),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                if (c.needsBuyerSignature)
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.yellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bookings Section ──

  Widget _buildBookingsSection(AsyncValue<List<Booking>> bookings) {
    return bookings.when(
      loading: () => _buildExpandableSection(
        icon: '📋', title: 'Мои бронирования', count: 0,
        expanded: _bookingsExpanded,
        onToggle: () => setState(() => _bookingsExpanded = !_bookingsExpanded),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (_, __) => _buildExpandableSection(
        icon: '📋', title: 'Мои бронирования', count: 0,
        expanded: _bookingsExpanded,
        onToggle: () => setState(() => _bookingsExpanded = !_bookingsExpanded),
        child: const Text('Ошибка загрузки', style: TextStyle(color: AppTheme.error)),
      ),
      data: (list) {
        // Сортируем: новые первые
        final sorted = List<Booking>.from(list)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _buildExpandableSection(
          icon: '📋',
          title: 'Мои бронирования',
          count: sorted.length,
          expanded: _bookingsExpanded,
          onToggle: () => setState(() => _bookingsExpanded = !_bookingsExpanded),
          child: sorted.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Нет бронирований', style: TextStyle(color: AppTheme.textMuted))),
                )
              : Column(children: sorted.map(_bookingCard).toList()),
        );
      },
    );
  }

  Widget _bookingCard(Booking b) {
    Color statusColor;
    switch (b.status) {
      case 'ACTIVE':
        statusColor = const Color(0xFF4ECB71);
        break;
      case 'CONVERTED':
        statusColor = const Color(0xFF6495ED);
        break;
      default:
        statusColor = AppTheme.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Кв. №${b.apartmentNumber ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (b.consultantName != null)
                  Text('Консультант: ${b.consultantName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text(b.createdAt.isNotEmpty ? b.createdAt.substring(0, 10) : '',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  // ── Payments Section ──

  Widget _buildPaymentsSection(AsyncValue<List<Map<String, dynamic>>> schedulesAsync) {
    return schedulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedules) {
        if (schedules.isEmpty) return const SizedBox.shrink();

        final overdueCount = schedules.where((s) => s['isOverdue'] == true).length;
        final paidCount = schedules.where((s) => s['isPaid'] == true).length;

        return _buildExpandableSection(
          icon: '💰',
          title: 'Мои платежи ($paidCount/${schedules.length})',
          count: schedules.length,
          expanded: _paymentsExpanded,
          onToggle: () => setState(() => _paymentsExpanded = !_paymentsExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overdueCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Просрочено: $overdueCount платеж(ей)',
                        style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ...schedules.map((s) => _paymentCard(s)),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentCard(Map<String, dynamic> payment) {
    final isPaid = payment['isPaid'] == true;
    final isOverdue = payment['isOverdue'] == true;
    final amount = (payment['amount'] is num) ? (payment['amount'] as num).toDouble() : 0.0;
    final dueDate = payment['dueDate'] ?? '';
    final paymentNumber = payment['paymentNumber'] ?? 0;
    final contractNumber = payment['contractNumber'] ?? '';

    Color statusColor;
    String statusIcon;
    String statusText;
    if (isPaid) {
      statusColor = const Color(0xFF4ECB71);
      statusIcon = '✅';
      statusText = 'Оплачен';
    } else if (isOverdue) {
      statusColor = AppTheme.error;
      statusIcon = '⚠️';
      statusText = 'Просрочен';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = '⏳';
      statusText = 'Ожидает';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppTheme.error.withOpacity(0.3)
              : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Text(statusIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Платёж #$paymentNumber — $contractNumber',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Дата: $dueDate',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt.format(amount)} сом',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

