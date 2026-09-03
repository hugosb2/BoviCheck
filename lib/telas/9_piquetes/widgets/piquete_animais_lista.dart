import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../8_rebanho/tela_detalhes_animal.dart';
import 'piquete_ficha.dart';

class PiqueteAnimaisLista extends StatelessWidget {
  final List<dynamic> animais;
  const PiqueteAnimaisLista({super.key, required this.animais});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const SecaoLabelPiquete(texto: 'Animais no Piquete'),
        if (animais.isNotEmpty) Text('${animais.length} ${animais.length == 1 ? 'registro' : 'registros'}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 14),
      if (animais.isEmpty) Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))), child: Column(children: [
        SvgPicture.asset(IconesApp.iconAnimalSvg, width: 56, height: 56, colorFilter: ColorFilter.mode(theme.colorScheme.outline.withValues(alpha: 0.5), BlendMode.srcIn)),
        const SizedBox(height: 16),
        Text('Nenhum animal neste piquete', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Use o menu acima para cadastrar um animal', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
      ]))
      else ...animais.asMap().entries.map((entry) {
        final i = entry.key;
        final animal = entry.value;
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: _ItemAnimal(animal: animal).animate().fadeIn(delay: (400 + i * 60).ms).slideX(begin: 0.08, end: 0));
      }),
    ]);
  }
}

class _ItemAnimal extends StatelessWidget {
  final dynamic animal;
  const _ItemAnimal({required this.animal});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sexoCor = animal.sexo == 'M' ? Colors.blue : Colors.pink;
    return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesAnimal(animal: animal))), borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)), child: SvgPicture.asset(IconesApp.iconAnimalSvg, width: 22, height: 22, colorFilter: ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(animal.brinco, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          if ((animal.nome ?? '').isNotEmpty) Text(animal.nome, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Row(children: [Text(animal.categoria, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 12)), if (animal.pesoAtualKg > 0) ...[const SizedBox(width: 8), Icon(Icons.monitor_weight_outlined, size: 12, color: theme.colorScheme.outline), const SizedBox(width: 2), Text('${animal.pesoAtualKg.toStringAsFixed(0)} kg', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 12))]]),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sexoCor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(animal.sexo == 'M' ? Icons.male : Icons.female, size: 14, color: sexoCor), const SizedBox(width: 3), Text(animal.sexo == 'M' ? 'M' : 'F', style: TextStyle(color: sexoCor, fontWeight: FontWeight.bold, fontSize: 11))])),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline.withValues(alpha: 0.5), size: 20),
      ]))));
  }
}
