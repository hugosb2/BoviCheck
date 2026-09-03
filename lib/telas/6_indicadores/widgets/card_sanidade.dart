import 'package:flutter/material.dart';
import '../../../servicos/calculadora_indicadores.dart';

class CardSanidade extends StatelessWidget {
  final double taxaMortalidade;
  final StatusIndicador status;
  final VoidCallback? onTap;
  const CardSanidade({super.key, required this.taxaMortalidade, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRuim = status == StatusIndicador.ruim;
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isRuim ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Icon(isRuim ? Icons.warning_amber_rounded : Icons.health_and_safety, color: isRuim ? theme.colorScheme.error : theme.colorScheme.primary, size: 32),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Taxa de Mortalidade', style: TextStyle(fontWeight: FontWeight.bold, color: isRuim ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer)),
          Text(isRuim ? 'Atenção! Taxa acima do aceitável.' : 'Dentro dos padrões esperados.', style: TextStyle(fontSize: 12, color: (isRuim ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer).withValues(alpha: 0.8))),
        ])),
        Text('${taxaMortalidade.toStringAsFixed(1)}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isRuim ? theme.colorScheme.error : theme.colorScheme.primary)),
      ]),
    );
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: card);
    return card;
  }
}
