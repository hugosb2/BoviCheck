import 'package:flutter/material.dart';
import '../../../estilos/icones.dart';
import '../../../modelos/piquete.dart';

class PiqueteHero extends StatelessWidget {
  final Piquete piquete;
  const PiqueteHero({super.key, required this.piquete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: SafeArea(bottom: false, child: Column(children: [
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(piquete.nome, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)), const SizedBox(height: 4), Text(piquete.tipo, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w500))])),
          Container(width: 68, height: 68, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(IconesApp.piquete, color: Colors.white, size: 34)),
        ]),
        if (piquete.descricao.isNotEmpty) ...[const SizedBox(height: 16), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Row(children: [Icon(Icons.description_outlined, color: Colors.white.withValues(alpha: 0.7), size: 20), const SizedBox(width: 10), Expanded(child: Text(piquete.descricao, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4)))]))],
      ])),
    );
  }
}
