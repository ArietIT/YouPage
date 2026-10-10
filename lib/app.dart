import 'package:animations/animations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youpage/core/settings/settings_provider.dart';
import 'package:youpage/core/theme/app_theme.dart';
import 'package:youpage/features/auth/auth_controller.dart';
import 'package:youpage/features/auth/login_page.dart';
import 'package:youpage/features/grades/presentation/grades_page.dart';

class YouPageApp extends ConsumerWidget {
  const YouPageApp({super.key});

  static const _seed = Color(0xFF6750A4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final light = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
        final dark = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
        return MaterialApp(
          title: 'YouPage',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.build(light),
          darkTheme: AppTheme.build(dark, amoled: settings.amoled),
          home: const _Root(),
        );
      },
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final Widget child = switch (auth.status) {
      AuthStatus.loading => const Scaffold(
          key: ValueKey('loading'),
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.loggedOut => const LoginPage(key: ValueKey('login')),
      AuthStatus.loggedIn => const GradesPage(key: ValueKey('grades')),
    };
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, animation, secondary) => SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      ),
      child: child,
    );
  }
}
