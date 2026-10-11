import 'dart:async';

import 'package:eduapge2/components/privacy_grade.dart';
import 'package:eduapge2/core/hidden_grades_store.dart';
import 'package:flutter/material.dart';

/// Считает три быстрых нажатия самостоятельно, не полагаясь на onDoubleTap.
class HideableGrade extends StatefulWidget {
  const HideableGrade({
    super.key,
    required this.id,
    required this.value,
    required this.onHide,
    required this.onRestore,
  });

  final String id;
  final String value;
  final Future<void> Function(String id) onHide;
  final Future<void> Function(String id) onRestore;

  @override
  State<HideableGrade> createState() => _HideableGradeState();
}

class _HideableGradeState extends State<HideableGrade> {
  bool _hidden = false;

  Future<void> _hide() async {
    setState(() => _hidden = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await widget.onHide(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hiddenGradesStore,
      builder: (context, _) {
        if (hiddenGradesStore.contains(widget.id)) {
          return HiddenGradeDot(id: widget.id, onRestore: widget.onRestore);
        }
        return AnimatedOpacity(
          opacity: _hidden ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          child: AnimatedScale(
            scale: _hidden ? .82 : 1,
            duration: const Duration(milliseconds: 260),
            child: PrivacyGrade(
                value: widget.value,
                style: const TextStyle(fontSize: 12),
                onTripleTap: _hide),
          ),
        );
      },
    );
  }
}

class HiddenGradeDot extends StatefulWidget {
  const HiddenGradeDot({super.key, required this.id, required this.onRestore});
  final String id;
  final Future<void> Function(String id) onRestore;

  @override
  State<HiddenGradeDot> createState() => _HiddenGradeDotState();
}

class _HiddenGradeDotState extends State<HiddenGradeDot> {
  DateTime? _lastTap;
  int _tapCount = 0;

  void _tap() {
    final now = DateTime.now();
    if (_lastTap == null ||
        now.difference(_lastTap!) > const Duration(milliseconds: 600)) {
      _tapCount = 0;
    }
    _lastTap = now;
    if (++_tapCount == 3) {
      _tapCount = 0;
      widget.onRestore(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Скрытая оценка',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: _tap,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Color(0x55444444), shape: BoxShape.circle),
              child: SizedBox(width: 5, height: 5),
            ),
          ),
        ),
      );
}
