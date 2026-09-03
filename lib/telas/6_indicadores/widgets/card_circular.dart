import 'package:flutter/material.dart';

class CardCircular extends StatelessWidget {
  final String titulo;
  final double porcentagem;
  final double meta;
  final Color cor;
  final String tooltip;
  final VoidCallback? onTap;
  const CardCircular({super.key, required this.titulo, required this.porcentagem, required this.meta, required this.cor, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentNormalizado = (porcentagem / 100).clamp(0.0, 1.0);
    final atingiuMeta = porcentagem >= meta;
    Widget card = Tooltip(
      message: tooltip, triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)), if (atingiuMeta) const Icon(Icons.star, size: 16, color: Colors.amber)]),
          const SizedBox(height: 16),
          Stack(alignment: Alignment.center, children: [
            SizedBox(height: 100, width: 100, child: CircularProgressIndicator(value: percentNormalizado, strokeWidth: 12, backgroundColor: cor.withValues(alpha: 0.1), color: cor, strokeCap: StrokeCap.round)),
            Column(children: [Text('${porcentagem.toStringAsFixed(1)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)), Text('Meta: ${meta.toInt()}%', style: TextStyle(fontSize: 10, color: theme.colorScheme.outline))]),
          ]),
        ]),
      ),
    );
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: card);
    return card;
  }
}
