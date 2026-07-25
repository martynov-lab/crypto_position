import 'package:flutter/material.dart';

/// Marks `capped_by_depth`: the book can't fill the whole computed size at the
/// quoted price, so the spread is thinner than it looks. Shared by the signal
/// cards and the coin chart header so both name the same flag the same way.
class DepthCapTag extends StatelessWidget {
  const DepthCapTag({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message:
          'В стакане недостаточно объёма по нужной цене, чтобы исполнить '
          'сделку на весь расчётный объём — реальный объём и прибыль могут '
          'оказаться меньше показанных.',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'мало объёма в стакане',
          style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
        ),
      ),
    );
  }
}
