import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import 'piquete_ficha.dart';

class PiqueteEstatisticas extends StatelessWidget {
  final int total, machos, femeas;
  final double pesoMedio;
  const PiqueteEstatisticas({super.key, required this.total, required this.machos, required this.femeas, required this.pesoMedio});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabelPiquete(texto: 'Rebanho'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _CardEstatistica(valor: '$total', label: total == 1 ? 'Animal' : 'Animais', cor: Theme.of(context).colorScheme.primary, svgIcone: IconesApp.iconAnimalSvg)),
        const SizedBox(width: 10),
        Expanded(child: _CardEstatistica(valor: '$machos', label: 'Machos', cor: Colors.blue, icone: Icons.male)),
        const SizedBox(width: 10),
        Expanded(child: _CardEstatistica(valor: '$femeas', label: 'Fêmeas', cor: Colors.pink, icone: Icons.female)),
        const SizedBox(width: 10),
        Expanded(child: _CardEstatistica(valor: pesoMedio > 0 ? pesoMedio.toStringAsFixed(0) : '—', label: 'Méd. Kg', cor: Colors.teal, icone: IconesApp.peso)),
      ]),
    ]);
  }
}

class _CardEstatistica extends StatelessWidget {
  final String valor, label;
  final Color cor;
  final IconData? icone;
  final String? svgIcone;
  const _CardEstatistica({required this.valor, required this.label, required this.cor, this.icone, this.svgIcone});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
      child: Column(children: [
        if (svgIcone != null) SvgPicture.asset(svgIcone!, width: 22, height: 22, colorFilter: ColorFilter.mode(cor, BlendMode.srcIn)) else Icon(icone, color: cor, size: 22),
        const SizedBox(height: 6),
        Text(valor, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
      ]));
  }
}
