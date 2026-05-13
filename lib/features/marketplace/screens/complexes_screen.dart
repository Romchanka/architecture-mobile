import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/marketplace_provider.dart';
import '../../../core/theme/app_theme.dart';

/// ComplexesScreen — shows residential complexes for a given company.
/// Navigation: Companies → [this] → Apartments
class ComplexesScreen extends ConsumerWidget {
  final int companyId;
  final String companyName;
  const ComplexesScreen({super.key, required this.companyId, required this.companyName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complexes = ref.watch(complexesProvider(companyId));

    return Scaffold(
      appBar: AppBar(title: Text(companyName)),
      body: complexes.when(
        loading: () => _buildShimmerList(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              const Text('Ошибка загрузки', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(complexesProvider(companyId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Нет жилых комплексов', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.invalidate(complexesProvider(companyId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _complexCard(context, list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _complexCard(BuildContext context, complex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed('/apartments', arguments: {
          'companyId': companyId,
          'complexId': complex.id,
          'complexName': complex.name,
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (complex.imageUrl != null)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: complex.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppTheme.surfaceLight,
                    highlightColor: AppTheme.surface,
                    child: Container(color: AppTheme.surfaceLight),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surfaceLight,
                    child: const Center(child: Icon(Icons.apartment, size: 48, color: AppTheme.textMuted)),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                color: AppTheme.surfaceLight,
                child: Center(
                  child: Icon(Icons.apartment_rounded, size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
              ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(complex.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (complex.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(complex.address!,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (complex.description != null) ...[
                    const SizedBox(height: 8),
                    Text(complex.description!,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceLight,
      highlightColor: AppTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 240,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
