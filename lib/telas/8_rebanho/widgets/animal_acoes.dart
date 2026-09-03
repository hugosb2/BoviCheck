import 'package:flutter/material.dart';
import '../../../estilos/icones.dart';
import '../../../modelos/animal.dart';
import '../../10_formularios/form_pesagem.dart';
import '../../10_formularios/form_reprodutivo.dart';
import '../../10_formularios/form_leite.dart';
import '../../10_formularios/form_sanitario.dart';
import '../../10_formularios/form_abate.dart';
import 'animal_ficha_grid.dart';

class AnimalAcoes extends StatelessWidget {
  final Animal animal;
  final VoidCallback onRefresh;
  const AnimalAcoes({super.key, required this.animal, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabel(texto: 'Ações Rápidas'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _AcaoItem(icone: IconesApp.peso, label: 'Pesagem', cor: Colors.indigo, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => FormPesagem(animalPreSelecionado: animal))); onRefresh(); })),
        const SizedBox(width: 12),
        Expanded(child: _AcaoItem(icone: Icons.favorite, label: 'Reprodutivo', cor: Colors.pink, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => FormReprodutivo(animalPreSelecionado: animal))); onRefresh(); })),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        if (animal.sexo == 'F' && animal.isAtivo && animal.categoria != 'Bezerra' && animal.categoria != 'Novilha')
          Expanded(child: _AcaoItem(icone: Icons.water_drop, label: 'Leite', cor: Colors.cyan, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => FormLeite(animalPreSelecionado: animal))); onRefresh(); }))
        else const Expanded(child: SizedBox.shrink()),
        const SizedBox(width: 12),
        Expanded(child: _AcaoItem(icone: Icons.medical_services, label: 'Sanitário', cor: Colors.red, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => FormSanitario(animalPreSelecionado: animal))); onRefresh(); })),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        if (animal.isAtivo && animal.status == 'Ativo') Expanded(child: _AcaoItem(icone: Icons.restaurant, label: 'Abate', cor: Colors.brown, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => FormAbate(animalPreSelecionado: animal))); onRefresh(); })) else const Expanded(child: SizedBox.shrink()),
        const Expanded(child: SizedBox.shrink()),
      ]),
    ]));
  }
}

class _AcaoItem extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color cor;
  final VoidCallback onTap;
  const _AcaoItem({required this.icone, required this.label, required this.cor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cor.withValues(alpha: 0.2))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icone, color: cor, size: 22), const SizedBox(width: 8), Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface))])));
  }
}
