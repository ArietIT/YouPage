import 'dart:ui';

import 'package:flutter/material.dart';

/// Базовые компоненты визуального языка YouPage Liquid Glass.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: .70),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: .38)),
              ),
              child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, required this.title, this.actions});
  final Widget title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: title, actions: actions, backgroundColor: Colors.transparent, elevation: 0);
}

class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({super.key, required this.destinations, required this.selectedIndex, required this.onDestinationSelected});
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        ),
      );
}

class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => FilledButton(onPressed: onPressed, child: child);
}

class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => GlassCard(child: child);
}

class GlassDialog extends StatelessWidget {
  const GlassDialog({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Dialog(backgroundColor: Colors.transparent, elevation: 0, child: GlassCard(child: child));
}
