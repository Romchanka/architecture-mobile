import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/marketplace_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

final _fmt = NumberFormat('#,##0', 'ru_RU');

class ApartmentDetailScreen extends ConsumerStatefulWidget {
  final int apartmentId;
  final int companyId;
  const ApartmentDetailScreen({super.key, required this.apartmentId, required this.companyId});

  @override
  ConsumerState<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends ConsumerState<ApartmentDetailScreen> {
  bool _booking = false;

  @override
  Widget build(BuildContext context) {
    final params = ApartmentDetailParams(widget.apartmentId, widget.companyId);
    final detail = ref.watch(apartmentDetailProvider(params));
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Детали квартиры')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(apartmentDetailProvider(params)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (apt) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary.withOpacity(0.15),
                      AppTheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Квартира №${apt.apartmentNumber}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: apt.status == 'AVAILABLE'
                                ? AppTheme.success.withOpacity(0.15)
                                : AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(apt.statusLabel,
                            style: TextStyle(
                              color: apt.status == 'AVAILABLE' ? AppTheme.success : AppTheme.warning,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('${_fmt.format(apt.totalPrice)} сом',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Layout plan image
              if (apt.layoutPlanUrl != null) ...[
                _sectionTitle('Планировка'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showFullImage(context, apt.layoutPlanUrl!),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: apt.layoutPlanUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => SizedBox(
                          height: 200,
                          child: Shimmer.fromColors(
                            baseColor: AppTheme.surfaceLight,
                            highlightColor: AppTheme.surface,
                            child: Container(color: AppTheme.surfaceLight),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Center(child: Icon(Icons.image_not_supported, size: 48, color: AppTheme.textMuted)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Info grid
              _sectionTitle('Характеристики'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _infoRow('Комнаты', '${apt.rooms}'),
                    _infoRow('Этаж', '${apt.floor}'),
                    _infoRow('Общая площадь', '${apt.areaTotal} м²'),
                    if (apt.areaLiving != null) _infoRow('Жилая площадь', '${apt.areaLiving} м²'),
                    if (apt.areaKitchen != null) _infoRow('Кухня', '${apt.areaKitchen} м²'),
                    _infoRow('Цена за м²', '${_fmt.format(apt.pricePerSqm)} сом'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mortgage calculator placeholder
              _sectionTitle('Калькулятор рассрочки'),
              const SizedBox(height: 12),
              _mortgageCalculator(apt.totalPrice),
              const SizedBox(height: 32),

              // Book button
              if (apt.status == 'AVAILABLE')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !auth.isAuthenticated || _booking ? null : () async {
                      setState(() => _booking = true);
                      try {
                        await bookApartment(widget.companyId, widget.apartmentId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Квартира забронирована!'), backgroundColor: AppTheme.success),
                          );
                          ref.invalidate(apartmentDetailProvider(params));
                          ref.invalidate(myBookingsProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppTheme.error),
                          );
                        }
                      } finally {
                        setState(() => _booking = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _booking
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(auth.isAuthenticated ? 'Забронировать' : 'Войдите для бронирования',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(color: AppTheme.primary),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                ),
              ),
            ),
            Positioned(
              top: 40, right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _mortgageCalculator(double totalPrice) {
    final months = [12, 24, 36, 48, 60];
    final downPayment = totalPrice * 0.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Первоначальный взнос (30%): ${_fmt.format(downPayment)} сом',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          ...months.map((m) {
            final monthly = (totalPrice - downPayment) / m;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$m мес.', style: const TextStyle(color: AppTheme.textSecondary)),
                  Text('${_fmt.format(monthly)} сом/мес',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
