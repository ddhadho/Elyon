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
    ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(deviceStateProvider);
          ref.invalidate(devicesProvider);
          ref.invalidate(eventsProvider);
        },
        child: devicesAsync.when(
          loading: () => const _LoadingGrid(),
          error:   (e, _) => _ErrorView(message: e.toString(), ref: ref),
          data: (devices) => stateAsync.when(
            loading: () => const _LoadingGrid(),
            error:   (e, _) => _ErrorView(message: e.toString(), ref: ref),
            data: (stateMap) {
              if (devices.isEmpty) return const _EmptyState();

              final visible = devices
                  .where((d) => stateMap.containsKey(d.id))
                  .toList();

              final safeDefaultCount = stateMap.values
                  .where((s) => s.isSafeDefaultActive)
                  .length;

              final activeCount = stateMap.values.where((s) {
                final v = s.getEffective('state');
                return v == 'on' || v == 'locked' || v == 'kplc';
              }).length;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [

                  // ── Header
                  SliverToBoxAdapter(
                    child: _Header(
                      activeCount: activeCount,
                      safeDefaultCount: safeDefaultCount,
                      onRefresh: () {
                        ref.invalidate(deviceStateProvider);
                        ref.invalidate(devicesProvider);
                        ref.invalidate(eventsProvider);
                      },
                      onSettings: () => context.push('/settings'),
                    ),
                  ),

                  // ── Safe default banner
                  if (safeDefaultCount > 0)
                    SliverToBoxAdapter(
                    ),

                  // ── Section label
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Text(
                        'DEVICES',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // ── Device grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final device = visible[i];
                          final state  = stateMap[device.id]!;
                          return DeviceCard(device: device, state: state);
                        },
                        childCount: visible.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing:  10,
                        childAspectRatio: 0.95,
                      ),
                    ),
                  ),

                  // ── Bottom padding so last card isn't hidden by activity strip
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ),

      // ── Bottom nav + activity strip stacked
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Nav bar
          NavigationBar(
            height: 60,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.history_rounded), label: 'Activity'),
              NavigationDestination(
                  icon: Icon(Icons.tune_rounded), label: 'Rules'),
            ],
            onDestinationSelected: (i) {
              if (i == 1) context.push('/activity');
              if (i == 2) context.push('/rules');
            },
            selectedIndex: 0,
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final int activeCount;
  final int safeDefaultCount;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  const _Header({
    required this.activeCount,
    required this.safeDefaultCount,
    required this.onRefresh,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top row: home name + actions
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<String?>(
                    future: AppConfig.getOwnerName(),
                    builder: (context, snap) => Text(
                      snap.data ?? 'Home',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: onRefresh,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceAlt,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: onSettings,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceAlt,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Summary chips
            Row(
              children: [
                _SummaryChip(
                  label: '$activeCount active',
                  color: activeCount > 0 ? AppColors.green : AppColors.textMuted,
                  bg: activeCount > 0
                      ? AppColors.green.withOpacity(0.1)
                      : AppColors.surfaceAlt,
                ),
                if (safeDefaultCount > 0) ...[
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: '$safeDefaultCount safe default',
                    color: AppColors.yellow,
                    bg: AppColors.yellow.withOpacity(0.1),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _SummaryChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Loading grid ──────────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface,
          border: Border.all(color: const Color(0x12000000), width: 0.5),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 52, color: AppColors.textMuted),
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

// ── Error view ────────────────────────────────────────────────────────────────

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
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(deviceStateProvider);
                ref.invalidate(devicesProvider);
                ref.invalidate(eventsProvider);
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