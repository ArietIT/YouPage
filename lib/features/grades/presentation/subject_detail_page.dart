import 'package:flutter/material.dart';
import 'package:youpage/core/theme/app_theme.dart';
import 'package:youpage/features/grades/domain/grade.dart';
import 'package:youpage/features/grades/presentation/widgets/privacy_grade.dart';

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key, required this.group});

  final SubjectGrades group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(group.name)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              itemCount: group.grades.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(kRadiusXL),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Средний балл',
                              style: tt.titleMedium?.copyWith(color: cs.onSecondaryContainer)),
                        ),
                        GradeBadge(group.averageLabel, size: 56, emphasized: true),
                      ],
                    ),
                  );
                }
                final g = group.grades[i - 1];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(kRadiusL),
                  ),
                  child: Row(
                    children: [
                      GradeBadge(g.value),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.title.isEmpty ? 'Оценка' : g.title, style: tt.titleMedium),
                            if (g.date != null)
                              Text(formatDate(g.date!),
                                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
