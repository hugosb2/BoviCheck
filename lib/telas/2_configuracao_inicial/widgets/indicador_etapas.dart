import 'package:flutter/material.dart';

class IndicadorEtapas extends StatelessWidget {
  final int etapaAtual;
  const IndicadorEtapas({super.key, required this.etapaAtual});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(children: [
        _CirculoEtapa(index: 0, label: 'Dados', icone: Icons.badge_outlined, etapaAtual: etapaAtual),
        _LinhaEtapa(index: 0, etapaAtual: etapaAtual),
        _CirculoEtapa(index: 1, label: 'Local', icone: Icons.location_on_outlined, etapaAtual: etapaAtual),
        _LinhaEtapa(index: 1, etapaAtual: etapaAtual),
        _CirculoEtapa(index: 2, label: 'Sistema', icone: Icons.settings_outlined, etapaAtual: etapaAtual),
      ]),
    );
  }
}

class _CirculoEtapa extends StatelessWidget {
  final int index;
  final String label;
  final IconData icone;
  final int etapaAtual;
  const _CirculoEtapa({required this.index, required this.label, required this.icone, required this.etapaAtual});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAtivo = etapaAtual >= index;
    final isAtual = etapaAtual == index;
    return Expanded(child: Column(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: isAtual ? Colors.white : (isAtivo ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)), shape: BoxShape.circle), child: Icon(icone, size: 18, color: isAtual ? theme.colorScheme.primary : Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: isAtual ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
    ]));
  }
}

class _LinhaEtapa extends StatelessWidget {
  final int index;
  final int etapaAtual;
  const _LinhaEtapa({required this.index, required this.etapaAtual});
  @override
  Widget build(BuildContext context) {
    final isAtivo = etapaAtual > index;
    return Container(width: 20, height: 2, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isAtivo ? Colors.white : Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1)));
  }
}
