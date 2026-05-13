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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoriesSection(ref),
          Expanded(
            child: companies.when(
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
            ),
          ],
        ),
    );
  }

  Widget _companyCard(BuildContext context, company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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

  Widget _buildStoriesSection(WidgetRef ref) {
    final storiesAsync = ref.watch(activeStoriesProvider);

    return storiesAsync.when(
      data: (stories) {
        if (stories.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 110,
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length,
            itemBuilder: (context, i) {
              final story = stories[i];
              return GestureDetector(
                onTap: () => _showStoryDialog(context, story),
                child: Container(
                  width: 76,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.background, width: 2),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: story.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppTheme.surfaceLight),
                              errorWidget: (_, __, ___) => const Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showStoryDialog(BuildContext context, story) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: CachedNetworkImage(
                      imageUrl: story.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(height: 300, color: AppTheme.surfaceLight, child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => Container(height: 300, color: AppTheme.surfaceLight, child: const Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (story.description != null && story.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(story.description!, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.4)),
                        ],
                        if (story.linkUrl != null && story.linkUrl!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: launchUrl(Uri.parse(story.linkUrl!));
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Подробнее', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black54)]),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
