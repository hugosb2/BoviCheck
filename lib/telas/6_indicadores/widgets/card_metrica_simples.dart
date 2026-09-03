import 'package:flutter/material.dart';
import '../../../estilos/cores.dart';
import '../../../servicos/calculadora_indicadores.dart';

class CardMetricaSimples extends StatelessWidget {
  final String label;
  final String valor;
  final String meta;
  final StatusIndicador status;
  final IconData? icone;
  final VoidCallback? onTap;
  const CardMetricaSimples({super.key, required this.label, required this.valor, required this.meta, required this.status, this.icone, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color corStatus = _getCorStatus(status);
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [if (icone != null) ...[Icon(icone, size: 16, color: Colors.grey), const SizedBox(width: 6)], Expanded(child: Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12), overflow: TextOverflow.ellipsis)), Icon(Icons.circle, size: 8, color: corStatus)]),
        const SizedBox(height: 8),
        Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(meta, style: TextStyle(fontSize: 11, color: corStatus, fontWeight: FontWeight.w500)),
      ]),
    );
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: card);
    return card;
  }
}

Color _getCorStatus(StatusIndicador s) {
  switch (s) {
    case StatusIndicador.bom: return CoresApp.sucesso;
    case StatusIndicador.atencao: return CoresApp.atencao;
    case StatusIndicador.ruim: return CoresApp.erro;
    case StatusIndicador.neutro: return Colors.grey;
  }
}
