import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youpage/core/settings/settings_provider.dart';

/// Маскирует оценку ТОЛЬКО на уровне отрисовки (размытие или «•••»).
/// Тап / долгое нажатие раскрывают значение на 3 секунды; состояние
/// раскрытия живёт лишь в памяти виджета и нигде не сохраняется.
class PrivacyGrade extends ConsumerStatefulWidget {
  const PrivacyGrade({super.key, required this.value, this.style});

  final String value;
  final TextStyle? style;

  @override
  ConsumerState<PrivacyGrade> createState() => _PrivacyGradeState();
}

class _PrivacyGradeState extends ConsumerState<PrivacyGrade> {
  static const _revealDuration = Duration(seconds: 3);
  Timer? _timer;
  bool _revealed = false;

  void _reveal() {
    _timer?.cancel();
    setState(() => _revealed = true);
    _timer = Timer(_revealDuration, () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final masked = s.privacy && !_revealed;

    Widget content;
    if (s.dots) {
      content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(
          masked ? '•••' : widget.value,
          key: ValueKey(masked),
          style: widget.style,
        ),
      );
    } else {
      // Размытие (sigma 8) делает цифру нечитаемой; плавно анимируется при раскрытии.
      content = TweenAnimationBuilder<double>(
        tween: Tween<double>(end: masked ? 8.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, sigma, _) {
          final text = Text(widget.value, style: widget.style);
          if (sigma < 0.05) return text;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
            child: text,
          );
        },
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: s.privacy ? _reveal : null,
      onLongPress: s.privacy ? _reveal : null,
      child: Semantics(
        label: masked ? 'Оценка скрыта' : widget.value,
        excludeSemantics: true,
        child: content,
      ),
    );
  }
}

/// Скруглённый бейдж с оценкой (форма не размывается — только текст).
class GradeBadge extends StatelessWidget {
  const GradeBadge(this.value, {super.key, this.size = 52, this.emphasized = false});

  final String value;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: emphasized ? cs.primary : cs.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.4),
      ),
      alignment: Alignment.center,
      child: PrivacyGrade(
        value: value,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: emphasized ? cs.onPrimary : cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
