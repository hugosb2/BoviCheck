import 'package:flutter/material.dart';
import '../../../estilos/icones.dart';
import '../../9_piquetes/tela_lista_piquetes.dart';

class GridSecundario extends StatelessWidget {
  final int totalPiquetes;
  final double totalLeiteMes;
  final double mediaGMD;
  final int totalDoentes;
  const GridSecundario({super.key, required this.totalPiquetes, required this.totalLeiteMes, required this.mediaGMD, required this.totalDoentes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Expanded(child: _CardStatPequeno(theme: theme, titulo: 'Piquetes', valor: totalPiquetes.toString(), icone: IconesApp.piquete, cor: Colors.orange.shade700, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaListaPiquetes())))),
      const SizedBox(width: 12),
      Expanded(child: _CardStatPequeno(theme: theme, titulo: 'Leite (mês)', valor: '${totalLeiteMes.toStringAsFixed(0)} L', icone: IconesApp.leite, cor: Colors.cyan.shade700)),
      const SizedBox(width: 12),
      Expanded(child: _CardStatPequeno(theme: theme, titulo: 'GMD Médio', valor: '${mediaGMD.toStringAsFixed(2)} kg', icone: IconesApp.peso, cor: Colors.teal.shade700)),
      const SizedBox(width: 12),
      Expanded(child: _CardStatPequeno(theme: theme, titulo: 'Alertas', valor: totalDoentes.toString(), icone: IconesApp.iaAtencao, cor: totalDoentes > 0 ? Colors.red.shade700 : Colors.green.shade700)),
    ]);
  }
}

class _CardStatPequeno extends StatelessWidget {
  final ThemeData theme;
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final VoidCallback? onTap;
  const _CardStatPequeno({required this.theme, required this.titulo, required this.valor, required this.icone, required this.cor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withValues(alpha: 0.2), width: 1.2)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(height: 8),
          Text(valor, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cor), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(titulo, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
