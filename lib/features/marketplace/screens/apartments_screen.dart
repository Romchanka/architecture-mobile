import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marketplace_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/floor_plan_widget.dart';

class ApartmentsScreen extends ConsumerStatefulWidget {
  final int companyId;
  final int? complexId;
  final String? complexName;
  const ApartmentsScreen({super.key, required this.companyId, this.complexId, this.complexName});

  @override
  ConsumerState<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends ConsumerState<ApartmentsScreen> {
  ApartmentFilter get _filter => ApartmentFilter(
    companyId: widget.companyId,
    complexId: widget.complexId,
  );

  @override
  Widget build(BuildContext context) {
    final apartments = ref.watch(apartmentsProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.complexName ?? 'Квартиры'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/parking', arguments: {
                'companyId': widget.companyId,
              });
            },
            icon: const Icon(Icons.local_parking, color: Colors.white),
            label: const Text('Паркинг', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
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
}
