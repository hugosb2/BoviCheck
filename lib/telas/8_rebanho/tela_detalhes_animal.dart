import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../modelos/animal.dart';
import '../../modelos/piquete.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/banco_dados_servico.dart';
import 'form_animal.dart';
import 'widgets/animal_hero.dart';
import 'widgets/animal_ficha_grid.dart';
import 'widgets/animal_peso_card.dart';
import 'widgets/animal_acoes.dart';
import 'widgets/animal_historico.dart';

class TelaDetalhesAnimal extends StatefulWidget {
  final Animal animal;
  const TelaDetalhesAnimal({super.key, required this.animal});
  @override
  State<TelaDetalhesAnimal> createState() => _TelaDetalhesAnimalState();
}

class _TelaDetalhesAnimalState extends State<TelaDetalhesAnimal> {
  List<Map<String, dynamic>> _historico = [];
  bool _carregandoHistorico = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final animalId = widget.animal.id;
    final db = BancoDadosServico.instancia;
    final pesagens = await db.getPesagensPorAnimal(animalId);
    final reprodutivos = await db.getEventosReprodutivosPorAnimal(animalId);
    final leite = await db.getProducaoLeitePorAnimal(animalId);
    final sanitarios = await db.getEventosSanitariosPorAnimal(animalId);
    final abates = await db.getAbatesPorAnimal(animalId);
    List<Map<String, dynamic>> temp = [];
    for (var p in pesagens) temp.add({'tipo': 'Pesagem', 'data': p.data, 'desc': '${p.pesoKg} kg', 'id': p.id, 'tabela': 'pesagens'});
    for (var r in reprodutivos) temp.add({'tipo': 'Reprodutivo', 'data': r.data, 'desc': '${r.tipo} ${r.resultado != null ? '(${r.resultado})' : ''}', 'id': r.id, 'tabela': 'eventos_reprodutivos'});
    for (var l in leite) temp.add({'tipo': 'Leite', 'data': l.data, 'desc': '${l.litros} L - ${l.periodo}', 'id': l.id, 'tabela': 'producao_leite'});
    for (var s in sanitarios) temp.add({'tipo': 'Sanitário', 'data': DateTime.parse(s['data'].toString()), 'desc': '${s['tipo']} ${s['nomeMedicamento'] ?? ''}', 'id': s['id'], 'tabela': 'eventos_sanitarios'});
    for (var a in abates) temp.add({'tipo': 'Abate', 'data': DateTime.parse(a['data'].toString()), 'desc': '${a['pesoCarcacaKg']} kg carcaça', 'id': a['id'], 'tabela': 'abates'});
    temp.sort((a, b) => (b['data'] as DateTime).compareTo(a['data'] as DateTime));
    if (mounted) setState(() {_historico = temp; _carregandoHistorico = false;});
  }

  Future<void> _confirmarDelecaoAnimal(Animal animal) async {
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: const Text('Excluir animal?'), content: Text('Excluir o animal "${animal.nome ?? animal.brinco}" (brinco ${animal.brinco})? Todos os registros vinculados também serão removidos. Esta ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('EXCLUIR'))]));
    if (confirmar != true || !mounted) return;
    await context.read<ProvedorFazenda>().excluirAnimal(animal.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Animal "${animal.nome ?? animal.brinco}" excluído')));
  }

  Future<void> _confirmarDelecaoEvento(Map<String, dynamic> evento) async {
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: const Text('Excluir registro?'), content: Text('Excluir o registro "${evento['tipo']}" (${evento['desc']})? Esta ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('EXCLUIR'))]));
    if (confirmar != true || !mounted) return;
    final provedor = context.read<ProvedorFazenda>();
    final id = evento['id'] as String;
    switch (evento['tabela']) {
      case 'pesagens': await provedor.excluirPesagem(id); break;
      case 'eventos_reprodutivos': await provedor.excluirEventoReprodutivo(id); break;
      case 'producao_leite': await provedor.excluirProducaoLeite(id); break;
      case 'eventos_sanitarios': await provedor.excluirEventoSanitario(id); break;
      case 'abates': await provedor.excluirAbate(id); break;
    }
    _carregarHistorico();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registro "${evento['tipo']}" excluído')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final animalAtual = provedor.animais.firstWhere((a) => a.id == widget.animal.id, orElse: () => widget.animal);
    final Piquete? piquete = provedor.piquetes.isEmpty ? null : provedor.piquetes.cast<Piquete?>().firstWhere((p) => p?.id == animalAtual.loteId, orElse: () => null);
    final bool inativo = !animalAtual.isAtivo;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarPadrao(titulo: animalAtual.nome ?? 'Animal #${animalAtual.brinco}', actions: [
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormAnimal(animalExistente: animalAtual)))),
        IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Excluir animal', onPressed: () => _confirmarDelecaoAnimal(animalAtual)),
      ]),
      body: ListView(padding: const EdgeInsets.only(bottom: 100), children: [
        AnimalHero(animal: animalAtual, piquete: piquete, inativo: inativo).animate().fadeIn(duration: 300.ms),
        if (inativo) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)), child: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24), const SizedBox(width: 12), Expanded(child: Text('Este animal está inativo/morto.', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 15)))]))).animate().fadeIn(),
        Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 0), child: AnimalFichaGrid(animal: animalAtual, piquete: piquete)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        AnimalPesoCard(animal: animalAtual).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 32),
        AnimalAcoes(animal: animalAtual, onRefresh: _carregarHistorico).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 32),
        AnimalHistorico(historico: _historico, carregando: _carregandoHistorico, onDelete: _confirmarDelecaoEvento).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 40),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormAnimal(animalExistente: animalAtual))), icon: const Icon(Icons.edit), label: const Text('EDITAR')),
    );
  }
}
