import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BarraProgressoModerno extends StatelessWidget {
  final int etapaAtual;
  final int total;
  const BarraProgressoModerno({super.key, required this.etapaAtual, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(total, (i) {
          final ativo = i <= etapaAtual;
          return Expanded(
            child: AnimatedContainer(
              duration: 400.ms,
              height: 6,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: ativo ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}
