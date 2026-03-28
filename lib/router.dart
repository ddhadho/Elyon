import 'package:go_router/go_router.dart';
import 'core/config/app_config.dart';
import 'features/connection/connection_screen.dart';
import 'features/home/home_screen.dart';
import 'features/activity/activity_screen.dart';
import 'features/rules/rules_screen.dart';
import 'features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) async {
    final configured = await AppConfig.isConfigured();
    // Only redirect to /connect if not configured AND not already heading there
    if (!configured && state.matchedLocation != '/connect') {
      return '/connect';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/connect',  builder: (_, _) => const ConnectionScreen()),
    GoRoute(path: '/home',     builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/activity', builder: (_, _) => const ActivityScreen()),
    GoRoute(path: '/rules',    builder: (_, _) => const RulesScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
  ],
);