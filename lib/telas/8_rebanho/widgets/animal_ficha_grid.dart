import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../../modelos/animal.dart';
import '../../../modelos/piquete.dart';

class AnimalFichaGrid extends StatelessWidget {
  final Animal animal;
  final Piquete? piquete;
  const AnimalFichaGrid({super.key, required this.animal, required this.piquete});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabel(texto: 'Ficha Técnica'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _FichaItem(icone: IconesApp.piquete, rotulo: 'Piquete', valor: piquete?.nome ?? '—', cor: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _FichaItem(icone: IconesApp.iconAnimalSvg, rotulo: 'Raça', valor: animal.raca)),
        const SizedBox(width: 12),
        Expanded(child: _FichaItem(icone: Icons.cake_outlined, rotulo: 'Idade', valor: '${animal.calcularIdadeMeses()} meses', cor: Colors.purple)),
      ]),
    ]);
  }
}

class _FichaItem extends StatelessWidget {
  final dynamic icone;
  final String rotulo;
  final String valor;
  final Color? cor;
  const _FichaItem({required this.icone, required this.rotulo, required this.valor, this.cor});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = cor ?? theme.colorScheme.primary;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.15))),
      child: Column(children: [
        icone is IconData ? Icon(icone, color: c, size: 24) : SvgPicture.asset(icone as String, width: 24, height: 24, colorFilter: ColorFilter.mode(c, BlendMode.srcIn)),
        const SizedBox(height: 8),
        Text(valor, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(rotulo, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]));
  }
}

class SecaoLabel extends StatelessWidget {
  final String texto;
  const SecaoLabel({super.key, required this.texto});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(texto, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]);
  }
}
