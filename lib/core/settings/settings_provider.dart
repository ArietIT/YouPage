import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настройки интерфейса. Сохраняется только сам флаг режима приватности,
/// но НЕ состояние временного раскрытия конкретных оценок.
class SettingsState {
  const SettingsState({
    this.privacy = true,
    this.dots = false,
    this.amoled = false,
    this.themeMode = ThemeMode.system,
  });

  final bool privacy;
  final bool dots;
  final bool amoled;
  final ThemeMode themeMode;

  SettingsState copyWith({
    bool? privacy,
    bool? dots,
    bool? amoled,
    ThemeMode? themeMode,
  }) =>
      SettingsState(
        privacy: privacy ?? this.privacy,
        dots: dots ?? this.dots,
        amoled: amoled ?? this.amoled,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _load();
    return const SettingsState(); // до загрузки оценки скрыты (privacy = true)
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final idx = (p.getInt('theme') ?? 0).clamp(0, ThemeMode.values.length - 1);
    state = SettingsState(
      privacy: p.getBool('privacy') ?? true,
      dots: p.getBool('dots') ?? false,
      amoled: p.getBool('amoled') ?? false,
      themeMode: ThemeMode.values[idx],
    );
  }

  Future<void> togglePrivacy() async {
    state = state.copyWith(privacy: !state.privacy);
    (await SharedPreferences.getInstance()).setBool('privacy', state.privacy);
  }

  Future<void> toggleDots() async {
    state = state.copyWith(dots: !state.dots);
    (await SharedPreferences.getInstance()).setBool('dots', state.dots);
  }

  Future<void> toggleAmoled() async {
    state = state.copyWith(amoled: !state.amoled);
    (await SharedPreferences.getInstance()).setBool('amoled', state.amoled);
  }

  Future<void> cycleTheme() async {
    final next = ThemeMode.values[(state.themeMode.index + 1) % ThemeMode.values.length];
    state = state.copyWith(themeMode: next);
    (await SharedPreferences.getInstance()).setInt('theme', next.index);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
