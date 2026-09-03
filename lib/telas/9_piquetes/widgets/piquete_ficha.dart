import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../../modelos/piquete.dart';

class PiqueteFicha extends StatelessWidget {
  final Piquete piquete;
  const PiqueteFicha({super.key, required this.piquete});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabelPiquete(texto: 'Ficha Técnica'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _FichaItem(icone: IconesApp.iconAnimalSvg, label: 'Capacidade', valor: piquete.capacidade > 0 ? '${piquete.capacidade} cab.' : '—', cor: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _FichaItem(icone: IconesApp.piquete, label: 'Área', valor: piquete.areaHectares > 0 ? '${piquete.areaHectares.toStringAsFixed(1)} ha' : '—', cor: Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _FichaItem(icone: Icons.agriculture_outlined, label: 'Sistema', valor: piquete.sistemaProducao, cor: Colors.brown)),
      ]),
    ]);
  }
}

class _FichaItem extends StatelessWidget {
  final dynamic icone;
  final String label;
  final String valor;
  final Color? cor;
  const _FichaItem({required this.icone, required this.label, required this.valor, this.cor});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corUsar = cor ?? theme.colorScheme.primary;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
      child: Column(children: [
        if (icone is String) SvgPicture.asset(icone, width: 24, height: 24, colorFilter: ColorFilter.mode(corUsar, BlendMode.srcIn)) else Icon(icone is IconData ? icone : Icons.info_outline, color: corUsar, size: 24),
        const SizedBox(height: 8),
        Text(valor, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11), textAlign: TextAlign.center),
      ]));
  }
}

class SecaoLabelPiquete extends StatelessWidget {
  final String texto;
  const SecaoLabelPiquete({super.key, required this.texto});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(texto, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]);
  }
}
