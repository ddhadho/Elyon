import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('APPEARANCE'),
          _ThemeToggleTile(
            isDark: isDark,
            onToggle: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const _SectionHeader('DAEMON'),
          _SettingsTile(
            icon: Icons.search_rounded,
            title: 'Device discovery',
            subtitle: 'Browse HA entities and add them to devices.toml',
            onTap: () => context.push('/discovery'),
          ),
          _SettingsTile(
            icon: Icons.router_rounded,
            title: 'Daemon connection',
            subtitle: 'Change the daemon address or access token',
            onTap: () => context.push('/connect'),
          ),
          _SettingsTile(
            icon: Icons.link_off_rounded,
            title: 'Disconnect',
            subtitle: 'Clear saved credentials and return to setup',
            destructive: true,
            onTap: () => _confirmDisconnect(context),
          ),
          const _SectionHeader('ABOUT'),
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: '2red2blue daemon',
            subtitle: 'Smarthome v1.0.0',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Disconnect?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will clear all saved credentials. '
          'You will need to reconnect to the daemon.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppConfig.clear();
      if (context.mounted) context.go('/connect');
    }
  }
}

// ── Theme toggle tile ─────────────────────────────────────────────────────────
class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile({required this.isDark, required this.onToggle});
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: AppColors.blue.withOpacity(0.12),
        ),
        child: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 18,
          color: AppColors.blue,
        ),
      ),
      title: Text(
        isDark ? 'Dark mode' : 'Light mode',
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isDark ? 'Using Home Assistant theme' : 'Using premium light theme',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (_) => onToggle(),
        activeColor: AppColors.orange,
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color     = destructive ? AppColors.red  : AppColors.textPrimary;
    final iconColor = destructive ? AppColors.red  : AppColors.blue;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: iconColor.withOpacity(0.12),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textMuted)
          : null,
      onTap: onTap,
    );
  }
}