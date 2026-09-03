import 'package:flutter/material.dart';
import '../../5_ia_consultor/tela_ia_consultor.dart';

class CardInsightIA extends StatelessWidget {
  final int totalDoentes;
  final double mediaGMD;
  const CardInsightIA({super.key, required this.totalDoentes, required this.mediaGMD});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temAlerta = totalDoentes > 0;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaIAConsultor())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: temAlerta ? Colors.red.shade50 : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: temAlerta ? Colors.red.shade200 : theme.colorScheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: temAlerta ? Colors.red : theme.colorScheme.primary, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: (temAlerta ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(temAlerta ? Icons.warning_rounded : Icons.auto_awesome, color: Colors.white, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Consultor IA', style: theme.textTheme.labelMedium?.copyWith(color: temAlerta ? Colors.red.shade700 : theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 4),
            Text(temAlerta ? '$totalDoentes animal(is) com alerta de saúde' : 'Rebanho saudável! GMD médio de ${mediaGMD.toStringAsFixed(2)} kg.',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: temAlerta ? Colors.red.shade800 : theme.colorScheme.onSurface, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
        ]),
      ),
    );
  }
}
