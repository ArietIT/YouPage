import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранит только идентификаторы скрытых оценок, без значений и названий.
class HiddenGradesStore extends ChangeNotifier {
  static const _storageKey = 'hidden_grade_ids_v1';
  final FlutterSecureStorage _storage;
  final Set<String> _ids = <String>{};

  HiddenGradesStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Set<String> get ids => Set.unmodifiable(_ids);
  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    final raw = await _storage.read(key: _storageKey);
    _ids
      ..clear()
      ..addAll((raw ?? '').split(',').where((id) => id.isNotEmpty));
    notifyListeners();
  }

  Future<void> hide(String id) async {
    _ids.add(id);
    await _save();
  }

  Future<void> restore(String id) async {
    _ids.remove(id);
    await _save();
  }

  Future<void> restoreAll() async {
    _ids.clear();
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }

  Future<void> removeMissing(Iterable<String> existingIds) async {
    final existing = existingIds.toSet();
    final before = _ids.length;
    _ids.removeWhere((id) => !existing.contains(id));
    if (_ids.length != before) await _save();
  }

  Future<void> clearForLogout() => restoreAll();

  Future<void> _save() async {
    await _storage.write(key: _storageKey, value: _ids.join(','));
    notifyListeners();
  }
}

final hiddenGradesStore = HiddenGradesStore();
