class Grade {
  const Grade({
    required this.id,
    required this.subject,
    required this.value,
    this.title = '',
    this.date,
  });

  final String id;
  final String subject;
  final String value;
  final String title;
  final DateTime? date;

  /// Числовое значение для расчёта среднего (null, если оценка нечисловая).
  double? get numeric {
    final m = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(value);
    if (m == null) return null;
    return double.tryParse(m.group(0)!.replaceAll(',', '.'));
  }
}

class SubjectGrades {
  const SubjectGrades(this.name, this.grades);

  final String name;
  final List<Grade> grades;

  double? get average {
    final nums = grades.map((g) => g.numeric).whereType<double>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }

  String get averageLabel => average?.toStringAsFixed(2) ?? '—';
}

List<SubjectGrades> groupBySubject(List<Grade> grades) {
  final map = <String, List<Grade>>{};
  for (final g in grades) {
    map.putIfAbsent(g.subject, () => []).add(g);
  }
  final result = map.entries.map((e) => SubjectGrades(e.key, e.value)).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return result;
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
