import 'package:flutter/material.dart';
import '../../../servicos/calculadora_indicadores.dart';

class CardProducaoDetalhado extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final StatusIndicador status;
  final String subtitulo;
  final VoidCallback? onTap;
  const CardProducaoDetalhado({super.key, required this.titulo, required this.valor, required this.icone, required this.cor, required this.status, required this.subtitulo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [cor.withValues(alpha: 0.1), theme.colorScheme.surface], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), border: Border.all(color: cor.withValues(alpha: 0.2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle), child: Icon(icone, color: cor, size: 32)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitulo, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(children: [Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)), const SizedBox(width: 8), ChipStatus(status: status)]),
        ])),
      ]),
    );
    if (onTap != null) return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: card);
    return card;
  }
}

class ChipStatus extends StatelessWidget {
  final StatusIndicador status;
  const ChipStatus({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    IconData icon; Color color;
    switch (status) {
      case StatusIndicador.bom: icon = Icons.arrow_upward; color = Colors.green; break;
      case StatusIndicador.atencao: icon = Icons.remove; color = Colors.orange; break;
      case StatusIndicador.ruim: icon = Icons.arrow_downward; color = Colors.red; break;
      case StatusIndicador.neutro: icon = Icons.horizontal_rule; color = Colors.grey; break;
    }
    return Icon(icon, color: color, size: 18);
  }
}
