import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved theme preference before first frame (no flash).
  final container = ProviderContainer();
  await container.read(themeModeProvider.notifier).loadSaved();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KayaApp(),
    ),
  );
}

class KayaApp extends ConsumerWidget {
  const KayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'smarthome',
      debugShowCheckedModeBanner: false,
      theme:     buildLightTheme(),   // new premium light
      darkTheme: buildDarkTheme(),    // your original HA dark
      themeMode: themeMode,
      routerConfig: router,           // your existing global GoRouter
    );
  }
}