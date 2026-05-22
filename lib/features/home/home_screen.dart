import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import 'package:elyon/shared/providers/api_providers.dart';
import '../../shared/providers/sse_provider.dart';
import '../../shared/theme/app_theme.dart';
import 'widgets/device_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sseNotifierProvider);

    final stateAsync   = ref.watch(deviceStateProvider);
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: FutureBuilder<String?>(
          future: AppConfig.getOwnerName(),
          builder: (context, snap) => Text(snap.data ?? 'Elyon'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(deviceStateProvider);
              ref.invalidate(devicesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blue,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(deviceStateProvider);
          ref.invalidate(devicesProvider);
        },
        child: devicesAsync.when(
          loading: () => const _LoadingGrid(),
          error:   (e, _) => _ErrorView(message: e.toString(), ref: ref),
          data: (devices) => stateAsync.when(
            loading: () => const _LoadingGrid(),
            error:   (e, _) => _ErrorView(message: e.toString(), ref: ref),
            data: (stateMap) {
              if (devices.isEmpty) return const _EmptyState();

              // Only show devices that have state — skip any not yet in stateMap
              final visible = devices
                  .where((d) => stateMap.containsKey(d.id))
                  .toList();

              return CustomScrollView(
                slivers: [
                  if (stateMap.values.any((s) => s.isSafeDefaultActive))
                    SliverToBoxAdapter(
                      child: _SafeDefaultBanner(
                        count: stateMap.values
                            .where((s) => s.isSafeDefaultActive)
                            .length,
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final device = visible[i];
                          final state  = stateMap[device.id]!; // safe: filtered above
                          return DeviceCard(device: device, state: state);
                        },
                        childCount: visible.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing:  12,
                        childAspectRatio: 1.8,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 60,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded),   label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.tune_rounded),    label: 'Rules'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) context.push('/activity');
          if (i == 2) context.push('/rules');
        },
        selectedIndex: 0,
      ),
    );
  }
}

class _SafeDefaultBanner extends StatelessWidget {
  final int count;
  const _SafeDefaultBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count device${count == 1 ? '' : 's'} acting on safe default',
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 1.1,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          border: Border.all(color: const Color(0xFF2A3A5C)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_outlined, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('No devices configured',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Add devices via devices.toml',
              style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final WidgetRef ref;
  const _ErrorView({required this.message, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(deviceStateProvider);
                ref.invalidate(devicesProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}