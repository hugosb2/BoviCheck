import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../estilos/icones.dart';
import 'animal_ficha_grid.dart';

class AnimalHistorico extends StatelessWidget {
  final List<Map<String, dynamic>> historico;
  final bool carregando;
  final Function(Map<String, dynamic>) onDelete;
  const AnimalHistorico({super.key, required this.historico, required this.carregando, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categorias = [const _CatReg('Pesagens', IconesApp.peso, 'Pesagem', Colors.indigo), const _CatReg('Reprodutivo', Icons.favorite, 'Reprodutivo', Colors.pink), const _CatReg('Produção de Leite', Icons.water_drop, 'Leite', Colors.cyan), const _CatReg('Sanitário', Icons.medical_services, 'Sanitário', Colors.red), const _CatReg('Abates', Icons.restaurant, 'Abate', Colors.brown)];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabel(texto: 'Registros por Categoria'),
      const SizedBox(height: 14),
      if (carregando) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
      else if (historico.isEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))), child: Column(children: [Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)), const SizedBox(height: 12), Text('Nenhum registro encontrado', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant))]))
      else ...categorias.map((cat) => _CardCategoria(theme: theme, cat: cat, historico: historico, onDelete: onDelete)),
    ]));
  }
}

class _CatReg {
  final String titulo;
  final IconData icone;
  final String tipo;
  final Color cor;
  const _CatReg(this.titulo, this.icone, this.tipo, this.cor);
}

class _CardCategoria extends StatelessWidget {
  final ThemeData theme;
  final _CatReg cat;
  final List<Map<String, dynamic>> historico;
  final Function(Map<String, dynamic>) onDelete;
  const _CardCategoria({required this.theme, required this.cat, required this.historico, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final eventos = historico.where((e) => e['tipo'] == cat.tipo).toList();
    if (eventos.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Container(decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: cat.cor.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cat.cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(cat.icone, color: cat.cor, size: 18)),
          const SizedBox(width: 10),
          Text(cat.titulo, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: cat.cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text('${eventos.length}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: cat.cor))),
        ])),
        ...eventos.map((e) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)))),
          child: Row(children: [Expanded(child: Text(e['desc'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))), Text(DateFormat('dd/MM').format(e['data'] as DateTime), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(width: 4), IconButton(icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error), visualDensity: VisualDensity.compact, tooltip: 'Excluir registro', onPressed: () => onDelete(e))])))),
        const SizedBox(height: 6),
      ]),
    ));
  }
}
