import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../modelos/piquete.dart';
import '../../provedores/provedor_fazenda.dart';
import 'widgets/piquete_hero.dart';
import 'widgets/piquete_ficha.dart';
import 'widgets/piquete_estatisticas.dart';
import 'widgets/piquete_acoes.dart';
import 'widgets/piquete_animais_lista.dart';

class TelaDetalhesPiquete extends StatefulWidget {
  final Piquete piquete;
  const TelaDetalhesPiquete({super.key, required this.piquete});
  @override
  State<TelaDetalhesPiquete> createState() => _TelaDetalhesPiqueteState();
}

class _TelaDetalhesPiqueteState extends State<TelaDetalhesPiquete> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final piqueteAtual = provedor.piquetes.firstWhere((p) => p.id == widget.piquete.id, orElse: () => widget.piquete);
    final animaisDoPiquete = provedor.animais.where((a) => a.loteId == piqueteAtual.id).toList();
    final total = animaisDoPiquete.length;
    final machos = animaisDoPiquete.where((a) => a.sexo == 'M').length;
    final femeas = animaisDoPiquete.where((a) => a.sexo == 'F').length;
    final pesoMedio = total > 0 ? animaisDoPiquete.fold<double>(0.0, (s, a) => s + a.pesoAtualKg) / total : 0.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarPadrao(titulo: piqueteAtual.nome, actions: [IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Excluir piquete', onPressed: () => _confirmarDelecaoPiquete(piqueteAtual, total))]),
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        PiqueteHero(piquete: piqueteAtual).animate().fadeIn().scale(),
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PiqueteFicha(piquete: piqueteAtual)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 28),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PiqueteEstatisticas(total: total, machos: machos, femeas: femeas, pesoMedio: pesoMedio)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 28),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PiqueteAcoes(piquete: piqueteAtual)).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 28),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: PiqueteAnimaisLista(animais: animaisDoPiquete)).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 40),
      ]),
    );
  }

  Future<void> _confirmarDelecaoPiquete(Piquete piquete, int totalAnimais) async {
    if (totalAnimais > 0) {
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: const Text('Piquete em uso'), content: Text('Este piquete possui $totalAnimais animal(is). Para excluí-lo, primeiro mova os animais para outro piquete (edite cada animal e troque o piquete).'), actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDI'))]));
      return;
    }
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: const Text('Excluir piquete?'), content: Text('Excluir o piquete "${piquete.nome}"? Esta ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('EXCLUIR'))]));
    if (confirmar != true || !mounted) return;
    await context.read<ProvedorFazenda>().excluirPiquete(piquete.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Piquete "${piquete.nome}" excluído')));
  }
}
