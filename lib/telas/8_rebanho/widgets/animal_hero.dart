import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../../modelos/animal.dart';
import '../../../modelos/piquete.dart';

class AnimalHero extends StatelessWidget {
  final Animal animal;
  final Piquete? piquete;
  final bool inativo;
  const AnimalHero({super.key, required this.animal, required this.piquete, required this.inativo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [inativo ? Colors.grey.shade700 : theme.colorScheme.primary, inativo ? Colors.grey.shade500 : theme.colorScheme.primary.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: (inativo ? Colors.grey : theme.colorScheme.primary).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: SafeArea(bottom: false, child: Column(children: [
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(animal.nome ?? 'Animal #${animal.brinco}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 4),
            Text('Brinco ${animal.brinco}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w500)),
          ])),
          Container(width: 68, height: 68, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(14), child: SvgPicture.asset(IconesApp.iconAnimalSvg, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          HeroBadge(texto: animal.sexo == 'M' ? 'Macho' : 'Fêmea', corFundo: animal.sexo == 'M' ? Colors.blue : Colors.pink),
          const SizedBox(width: 8),
          HeroBadge(texto: animal.categoria, corFundo: Colors.amber.shade400),
          const SizedBox(width: 8),
          if (piquete != null) HeroBadge(texto: piquete!.nome, corFundo: Colors.green.shade400),
        ]),
      ])),
    );
  }
}

class HeroBadge extends StatelessWidget {
  final String texto;
  final Color corFundo;
  const HeroBadge({super.key, required this.texto, required this.corFundo});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: corFundo.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: corFundo.withValues(alpha: 0.5))), child: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)));
}
