import 'package:flutter/material.dart';

class CabecalhoFazenda extends StatelessWidget {
  final dynamic propriedade;
  const CabecalhoFazenda({super.key, required this.propriedade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nome = propriedade.nomeFazenda.isEmpty ? 'BoviCheck' : propriedade.nomeFazenda;
    final iniciais = nome.length >= 2 ? nome.substring(0, 2).toUpperCase() : nome[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary.withValues(alpha: 0.15), theme.colorScheme.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(iniciais, style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -1))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(propriedade.nomeFazenda, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Flexible(child: Text('${propriedade.cidade}, ${propriedade.estado}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                  ]),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.waving_hand_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text("Olá, ${propriedade.nomeProprietario.split(' ').first}", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}
