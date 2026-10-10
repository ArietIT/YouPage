import 'package:youpage/features/grades/domain/grade.dart';

List<Grade> demoGrades() {
  final now = DateTime.now();
  DateTime ago(int d) => now.subtract(Duration(days: d));
  var n = 0;
  Grade g(String subject, String value, String title, int days) =>
      Grade(id: 'demo${n++}', subject: subject, value: value, title: title, date: ago(days));
  return [
    g('Математика', '5', 'Контрольная работа', 2),
    g('Математика', '4', 'Домашнее задание', 6),
    g('Математика', '5', 'Тест', 12),
    g('Физика', '3', 'Лабораторная', 3),
    g('Физика', '4', 'Самостоятельная', 9),
    g('Информатика', '5', 'Проект', 4),
    g('Информатика', '5', 'Практика', 10),
    g('История', '4', 'Устный ответ', 5),
    g('История', '2', 'Диктант', 14),
    g('Английский язык', '5', 'Эссе', 1),
    g('Английский язык', '4', 'Аудирование', 8),
  ];
}
