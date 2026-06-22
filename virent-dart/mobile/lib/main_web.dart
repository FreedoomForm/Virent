import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/configs/theme/app_theme.dart';
import 'core/configs/services/storage_service.dart';
import 'features/theme/presentation/providers/theme_provider.dart';
import 'app_router.dart';
import 'web_init.dart' if (dart.library.io) 'web_init_stub.dart';

void main() {
  initWeb();
  runApp(const ProviderScope(child: VirentWebApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return buildAppRouter(StorageService());
});

class VirentWebApp extends ConsumerWidget {
  const VirentWebApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider).isDark;
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Virent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
