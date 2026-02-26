import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/marketplace_provider.dart';
import '../../../core/theme/app_theme.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Застройщики'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // TODO: search
          ),
        ],
      ),
      body: companies.when(
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
                onPressed: () => ref.invalidate(companiesProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Нет застройщиков', style: TextStyle(color: AppTheme.textSecondary)))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async => ref.invalidate(companiesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _companyCard(context, list[i]),
                ),
              ),
      ),
    );
  }

  Widget _companyCard(BuildContext context, company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: company.logoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60, height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.all(4),
                  child: CachedNetworkImage(
                    imageUrl: company.logoUrl!,
                    width: 52, height: 52,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppTheme.surfaceLight,
                      highlightColor: AppTheme.surface,
                      child: Container(width: 60, height: 60, color: AppTheme.surfaceLight),
                    ),
                    errorWidget: (_, __, ___) => _companyInitial(company.name),
                  ),
                ),
              )
            : _companyInitial(company.name),
        title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: company.description != null
            ? Text(company.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: () => Navigator.of(context).pushNamed('/complexes', arguments: {
          'companyId': company.id,
          'companyName': company.name,
        }),
      ),
    );
  }

  Widget _companyInitial(String name) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
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
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
