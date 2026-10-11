import 'dart:async';
import 'dart:ui';

import 'package:eduapge2/core/privacy_settings.dart';
import 'package:flutter/material.dart';

class PrivacyGrade extends StatefulWidget {
  const PrivacyGrade({super.key, required this.value, this.style, this.onTripleTap});
  final String value;
  final TextStyle? style;
  final VoidCallback? onTripleTap;

  @override
  State<PrivacyGrade> createState() => _PrivacyGradeState();
}

class _PrivacyGradeState extends State<PrivacyGrade> {
  Timer? _timer;
  bool _revealed = false;
  DateTime? _lastTap;
  int _tapCount = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reveal() {
    _timer?.cancel();
    setState(() => _revealed = true);
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  void _handleTap() {
    _reveal();
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > const Duration(milliseconds: 600)) {
      _tapCount = 0;
    }
    _lastTap = now;
    if (++_tapCount == 3) {
      _tapCount = 0;
      widget.onTripleTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: privacySettings,
      builder: (context, _) {
        final visible = !privacySettings.enabled || _revealed;
        final grade = Text(widget.value, style: widget.style);
        if (visible) return grade;
        final masked = privacySettings.style == GradeMaskStyle.dots
            ? Text('•••', style: widget.style)
            : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: grade);
        return Semantics(
          label: 'Оценка скрыта',
          excludeSemantics: true,
          button: true,
          child: GestureDetector(onTap: _handleTap, onLongPress: _reveal, child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: KeyedSubtree(key: ValueKey(visible), child: masked))),
        );
      },
    );
  }
}
