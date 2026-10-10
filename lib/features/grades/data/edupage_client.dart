import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:youpage/features/grades/domain/grade.dart';

class EduPageException implements Exception {
  EduPageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Неофициальный клиент EduPage (официального API нет).
/// Вход — через веб-форму школы, оценки — парсинг JSON со страницы /znamky/.
class EduPageClient {
  EduPageClient() {
    _dio = _build();
  }

  late Dio _dio;
  CookieJar _jar = CookieJar();
  String? _school;

  Dio _build() {
    final d = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      responseType: ResponseType.plain,
      validateStatus: (s) => s != null && s < 500,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
      },
    ));
    d.interceptors.add(CookieManager(_jar));
    return d;
  }

  static String normalizeSchool(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r'^https?://'), '');
    s = s.split('/').first;
    if (s.endsWith('.edupage.org')) {
      s = s.substring(0, s.length - '.edupage.org'.length);
    }
    return s;
  }

  Future<void> login(String school, String user, String pass) async {
    final sub = normalizeSchool(school);
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(sub)) {
      throw EduPageException('Некорректный адрес школы');
    }
    _jar = CookieJar();
    _dio = _build();
    try {
      final page = await _dio.get<String>('https://$sub.edupage.org/login/');
      final html = page.data ?? '';
      final m = RegExp(r'''name=["']csrfauth["']\s+value=["']([^"']+)["']''').firstMatch(html);
      if (m == null) {
        throw EduPageException('Школа не найдена или страница входа изменилась');
      }
      final resp = await _dio.post<String>(
        'https://$sub.edupage.org/login/edubarLogin.php',
        data: {'csrfauth': m.group(1), 'username': user, 'password': pass},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final url = resp.realUri.toString();
      if (url.contains('bad=1') || (resp.data ?? '').contains('bad=1')) {
        throw EduPageException('Неверный логин или пароль');
      }
      _school = sub;
    } on DioException catch (e) {
      throw EduPageException('Ошибка сети: ${e.message ?? e.type.name}');
    }
  }

  void clear() {
    _school = null;
    _jar = CookieJar();
    _dio = _build();
  }

  Future<List<Grade>> fetchGrades() async {
    final sub = _school;
    if (sub == null) throw EduPageException('Нет активной сессии');
    try {
      final r = await _dio.get<String>('https://$sub.edupage.org/znamky/');
      final html = r.data ?? '';
      if (html.contains('name="csrfauth"')) {
        throw EduPageException('Сессия истекла, войдите заново');
      }
      final json = _extractJson(html, 'znamkyStudentViewer(');
      if (json == null) {
        throw EduPageException(
            'Не удалось найти оценки на странице (формат EduPage мог измениться)');
      }
      return GradeParser.parse(json);
    } on DioException catch (e) {
      throw EduPageException('Ошибка сети: ${e.message ?? e.type.name}');
    }
  }

  static dynamic _extractJson(String src, String marker) {
    final i = src.indexOf(marker);
    if (i < 0) return null;
    final from = i + marker.length;
    final start = src.indexOf(RegExp(r'[{\[]'), from);
    if (start < 0) return null;
    var depth = 0;
    var inStr = false;
    var esc = false;
    for (var k = start; k < src.length; k++) {
      final c = src[k];
      if (inStr) {
        if (esc) {
          esc = false;
        } else if (c == '\\') {
          esc = true;
        } else if (c == '"') {
          inStr = false;
        }
        continue;
      }
      if (c == '"') {
        inStr = true;
      } else if (c == '{' || c == '[') {
        depth++;
      } else if (c == '}' || c == ']') {
        depth--;
        if (depth == 0) {
          try {
            return jsonDecode(src.substring(start, k + 1));
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }
}

/// Устойчивый к изменениям формата разбор: ищет в JSON словарь предметов
/// и записи оценок (по характерным ключам), не завися от точной структуры.
class GradeParser {
  static dynamic _get(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  static bool _looksLikeGrade(Map m) =>
      _get(m, ['predmetid', 'predmetID', 'subjectid', 'subjectId']) != null &&
      _get(m, ['data', 'znamka', 'hodnota', 'value']) != null;

  static List<Grade> parse(dynamic json) {
    final subjects = <String, String>{};
    void collectSubjects(dynamic n) {
      if (n is Map) {
        for (final e in n.entries) {
          final k = e.key.toString().toLowerCase();
          if ((k == 'predmety' || k == 'subjects') && e.value is Map) {
            (e.value as Map).forEach((id, v) {
              if (v is Map) {
                final name = _get(v, ['name', 'nazov', 'short', 'p_nazov']);
                if (name != null) subjects[id.toString()] = name.toString();
              } else if (v is String) {
                subjects[id.toString()] = v;
              }
            });
          }
          collectSubjects(e.value);
        }
      } else if (n is List) {
        for (final x in n) {
          collectSubjects(x);
        }
      }
    }

    final found = <Map>[];
    void collectGrades(dynamic n) {
      if (n is Map) {
        if (_looksLikeGrade(n)) {
          found.add(n);
          return;
        }
        for (final v in n.values) {
          collectGrades(v);
        }
      } else if (n is List) {
        for (final x in n) {
          collectGrades(x);
        }
      }
    }

    collectSubjects(json);
    collectGrades(json);

    final result = <Grade>[];
    var idx = 0;
    for (final m in found) {
      var raw = _get(m, ['data', 'znamka', 'hodnota', 'value']);
      if (raw is Map) raw = _get(raw, ['val', 'value', 'znamka']);
      final value = raw?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      final pid = _get(m, ['predmetid', 'predmetID', 'subjectid', 'subjectId']).toString();
      final title = _get(m, ['nazov', 'title', 'popis'])?.toString() ?? '';
      final dateRaw = _get(m, ['udelene', 'datum', 'date'])?.toString();
      result.add(Grade(
        id: (_get(m, ['znamkaid', 'id', 'udalostid']) ?? 'g${idx++}').toString(),
        subject: subjects[pid] ?? 'Предмет $pid',
        value: value,
        title: title,
        date: dateRaw == null ? null : DateTime.tryParse(dateRaw),
      ));
    }
    result.sort((a, b) {
      final da = a.date, db = b.date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return result;
  }
}
