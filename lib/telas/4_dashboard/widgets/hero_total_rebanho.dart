import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../8_rebanho/tela_lista_animais.dart';

class HeroTotalRebanho extends StatelessWidget {
  final int totalAtivos;
  final int totalGeral;
  const HeroTotalRebanho({super.key, required this.totalAtivos, required this.totalGeral});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaListaAnimais())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
            child: SvgPicture.asset(IconesApp.iconAnimalSvg, width: 36, height: 36, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rebanho Ativo', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(totalAtivos.toString(), style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1)),
            if (totalAtivos != totalGeral) ...[
              const SizedBox(height: 2),
              Text('$totalGeral registrados no total', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
            ]
          ])),
          Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.7), size: 28),
        ]),
      ),
    );
  }
}
