import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/editor/presentation/editor_screen.dart';
import '../../features/filter_library/presentation/filter_library_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CameraScreen(),
        transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: '/filters',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FilterLibraryScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: '/gallery',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GalleryScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),
    GoRoute(
      path: '/editor',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final String imagePath;
        final String? assetId;
        if (extra is Map<String, dynamic>) {
          imagePath = extra['path'] as String? ?? '';
          assetId   = extra['assetId'] as String?;
        } else {
          imagePath = extra as String? ?? '';
          assetId   = null;
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: EditorScreen(imagePath: imagePath, assetId: assetId),
          transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
  ],
);
