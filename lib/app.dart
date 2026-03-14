import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/router.dart';
import 'core/theme/app_theme.dart';

class LikeThisApp extends ConsumerWidget {
  const LikeThisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Like This!',
      debugShowCheckedModeBanner: false,
      // Dark Mode Only
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
