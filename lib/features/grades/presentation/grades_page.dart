import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youpage/core/settings/settings_provider.dart';
import 'package:youpage/core/theme/app_theme.dart';
import 'package:youpage/features/auth/auth_controller.dart';
import 'package:youpage/features/grades/domain/grade.dart';
import 'package:youpage/features/grades/presentation/subject_detail_page.dart';
import 'package:youpage/features/grades/presentation/widgets/privacy_grade.dart';

class GradesPage extends ConsumerWidget {
  const GradesPage({super.key});

  static String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'системная',
        ThemeMode.light => 'светлая',
        ThemeMode.dark => 'тёмная',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(gradesProvider);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(gradesProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Оценки'),
              actions: [
                IconButton(
                  tooltip: s.privacy ? 'Показать оценки' : 'Скрыть оценки',
                  onPressed: notifier.togglePrivacy,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      s.privacy ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      key: ValueKey(s.privacy),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (v) {
                    switch (v) {
                      case 'dots':
                        notifier.toggleDots();
                      case 'amoled':
                        notifier.toggleAmoled();
                      case 'theme':
                        notifier.cycleTheme();
                      case 'logout':
                        ref.read(authProvider.notifier).logout();
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    CheckedPopupMenuItem<String>(
                      value: 'dots',
                      checked: s.dots,
                      child: const Text('Маска точками'),
                    ),
                    CheckedPopupMenuItem<String>(
                      value: 'amoled',
                      checked: s.amoled,
                      child: const Text('AMOLED-тема'),
                    ),
                    PopupMenuItem<String>(
                      value: 'theme',
                      child: Text('Тема: ${_themeLabel(s.themeMode)}'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(value: 'logout', child: Text('Выйти')),
                  ],
                ),
              ],
            ),
            grades.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.invalidate(gradesProvider),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (list) {
                final groups = groupBySubject(list);
                if (groups.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Оценок пока нет')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _SubjectCard(group: groups[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.group});

  final SubjectGrades group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusXL));
    final recent = group.grades.take(6).toList();

    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 450),
      closedElevation: 0,
      openElevation: 0,
      closedShape: shape,
      openShape: const RoundedRectangleBorder(),
      closedColor: cs.surfaceContainer,
      openColor: cs.surface,
      middleColor: cs.surface,
      closedBuilder: (context, open) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: tt.titleLarge),
                      const SizedBox(height: 2),
                      Text('Оценок: ${group.grades.length}',
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                GradeBadge(group.averageLabel, size: 56, emphasized: true),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final g in recent) GradeBadge(g.value, size: 40)],
            ),
          ],
        ),
      ),
      openBuilder: (context, close) => SubjectDetailPage(group: group),
    );
  }
}
