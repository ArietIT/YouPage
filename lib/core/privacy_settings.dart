import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GradeMaskStyle { blur, dots }

class PrivacySettings extends ChangeNotifier {
  static const _privacyKey = 'privacyGrades';
  static const _maskStyleKey = 'privacyGradeMaskStyle';

  bool _enabled = true;
  GradeMaskStyle _style = GradeMaskStyle.blur;

  bool get enabled => _enabled;
  GradeMaskStyle get style => _style;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(_privacyKey) ?? true;
    _style = (preferences.getString(_maskStyleKey) ?? 'blur') == 'dots'
        ? GradeMaskStyle.dots
        : GradeMaskStyle.blur;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyKey, value);
  }

  Future<void> setStyle(GradeMaskStyle value) async {
    _style = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_maskStyleKey, value.name);
  }
}

final privacySettings = PrivacySettings();
