import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/api_providers.dart';
import '../../core/models/event_summary.dart';
import '../../shared/theme/app_theme.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text('No events yet',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length,
            itemBuilder: (context, i) => _EventTile(event: events[i]),
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventSummary event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm · d MMM').format(event.timestamp);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(event.icon, style: const TextStyle(fontSize: 16)),
        ),
      ),
      title: Text(
        event.humanReadable,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        timeStr,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}