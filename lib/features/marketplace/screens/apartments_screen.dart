import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_models.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/floor_plan_widget.dart';

final _fmt = NumberFormat('#,##0', 'ru_RU');

class ApartmentsScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int? complexId;
  final String? complexName;
  const ApartmentsScreen({super.key, required this.companyId, this.complexId, this.complexName});

  @override
  ConsumerState<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends ConsumerState<ApartmentsScreen> {
  int? _selectedRooms;
  bool _showPlan = false;

  ApartmentFilter get _filter => ApartmentFilter(
    companyId: widget.companyId,
    complexId: widget.complexId,
    rooms: _showPlan ? null : _selectedRooms, // no room filter in plan mode
  );

  @override
  Widget build(BuildContext context) {
    final apartments = ref.watch(apartmentsProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.complexName ?? 'Квартиры'),
      ),
      body: apartments.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(apartmentsProvider(_filter)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (list) {
          return FloorPlanWidget(
            apartments: list,
            companyId: widget.companyId,
            complexName: widget.complexName,
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: selected ? Colors.black : AppTheme.textPrimary, fontWeight: FontWeight.w600),
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: selected ? AppTheme.primary : Colors.white.withAlpha(26)),
      ),
    );
  }

  Widget _apartmentCard(BuildContext context, Apartment apartment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed('/apartment-detail',
            arguments: {'id': apartment.id, 'companyId': widget.companyId}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Layout plan image
            if (apartment.layoutPlanUrl != null)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: apartment.layoutPlanUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppTheme.surfaceLight,
                    highlightColor: AppTheme.surface,
                    child: Container(color: AppTheme.surfaceLight),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surfaceLight,
                    child: const Center(child: Icon(Icons.grid_view_rounded, size: 48, color: AppTheme.textMuted)),
                  ),
                ),
              ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Кв. №${apartment.apartmentNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(apartment.statusLabel,
                          style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoChip(Icons.meeting_room_outlined, '${apartment.rooms}-комн.'),
                      const SizedBox(width: 12),
                      _infoChip(Icons.square_foot, '${apartment.areaTotal} м²'),
                      const SizedBox(width: 12),
                      _infoChip(Icons.stairs_outlined, '${apartment.floor} эт.'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${_fmt.format(apartment.totalPrice)} сом',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Text('${_fmt.format(apartment.pricePerSqm)} сом/м²',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceLight,
      highlightColor: AppTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
