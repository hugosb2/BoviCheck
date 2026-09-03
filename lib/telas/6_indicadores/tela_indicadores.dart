import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/calculadora_indicadores.dart';
import 'historico_reproducao.dart';
import 'historico_leite.dart';
import 'historico_pesagem.dart';
import 'historico_gmd.dart';
import 'historico_iep.dart';
import 'historico_mortalidade.dart';
import 'widgets/titulo_secao.dart';
import 'widgets/card_circular.dart';
import 'widgets/card_metrica_simples.dart';
import 'widgets/card_producao_detalhado.dart';
import 'widgets/card_sanidade.dart';
import 'widgets/periodo_chip.dart';

class TelaIndicadores extends StatefulWidget {
  const TelaIndicadores({super.key});
  @override
  State<TelaIndicadores> createState() => _TelaIndicadoresState();
}

class _TelaIndicadoresState extends State<TelaIndicadores> {
  DateTimeRange _periodoSelecionado = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 365)), end: DateTime.now());
  String? _loteSelecionadoId;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva != null && provedor.animais.isEmpty) {
          await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);
        }
      } catch (_) {}
      if (mounted) setState(() => _inicializado = true);
    });
  }

  void _atualizarPeriodo(int dias) => setState(() => _periodoSelecionado = DateTimeRange(start: DateTime.now().subtract(Duration(days: dias)), end: DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    if (!_inicializado) return Scaffold(backgroundColor: theme.colorScheme.surface, appBar: const AppBarPadrao(titulo: 'Performance'), body: const Center(child: CircularProgressIndicator()));
    if (provedor.propriedadeAtiva == null) return Scaffold(backgroundColor: theme.colorScheme.surface, appBar: const AppBarPadrao(titulo: 'Performance'), body: const Center(child: Text('Nenhuma fazenda selecionada.')));

    final animaisFiltrados = _loteSelecionadoId == null ? provedor.animais : provedor.animais.where((a) => a.loteId == _loteSelecionadoId).toList();
    final idsAnimais = animaisFiltrados.map((a) => a.id).toSet();
    final calc = CalculadoraIndicadores(
      animais: animaisFiltrados,
      pesagens: provedor.pesagens.where((e) => idsAnimais.contains(e.animalId)).toList(),
      reprodutivos: provedor.eventosReprodutivos.where((e) => idsAnimais.contains(e.animalId)).toList(),
      leite: provedor.producaoLeite.where((e) => idsAnimais.contains(e.animalId)).toList(),
      inicio: _periodoSelecionado.start, fim: _periodoSelecionado.end,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Performance'),
      body: ListView(padding: const EdgeInsets.all(16.0), children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String?>(value: _loteSelecionadoId, hint: const Text('Todos os Piquetes'), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded), items: [const DropdownMenuItem(value: null, child: Text('Rebanho Geral')), ...provedor.piquetes.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome)))], onChanged: (v) => setState(() => _loteSelecionadoId = v))),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [PeriodoChip('30 Dias', 30, _periodoSelecionado, _atualizarPeriodo), PeriodoChip('6 Meses', 180, _periodoSelecionado, _atualizarPeriodo), PeriodoChip('1 Ano', 365, _periodoSelecionado, _atualizarPeriodo), PeriodoChip('Tudo', 3650, _periodoSelecionado, _atualizarPeriodo)])),
        ]),
        const SizedBox(height: 24),
        const TituloSecao('Eficiência Reprodutiva'),
        Row(children: [
          Expanded(child: CardCircular(titulo: 'Natalidade', porcentagem: calc.taxaNatalidade, meta: 80, cor: Colors.pink, tooltip: 'Nascimentos / Fêmeas Aptas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())))),
          const SizedBox(width: 12),
          Expanded(child: CardCircular(titulo: 'Prenhez', porcentagem: calc.taxaPrenhez, meta: 85, cor: Colors.purple, tooltip: 'Diagnósticos Positivos', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())))),
        ]).animate().scale(duration: 400.ms),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CardMetricaSimples(label: 'IEP (Meses)', valor: calc.iepMeses.toStringAsFixed(1), meta: 'Meta: 12-14', status: calc.getStatusIEP(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoIEP())))),
          const SizedBox(width: 12),
          Expanded(child: CardMetricaSimples(label: '1º Parto (Meses)', valor: calc.idadePrimeiroPartoMeses.toStringAsFixed(1), meta: 'Meta: < 30', status: calc.getStatusIdadeParto(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())))),
        ]).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        const TituloSecao('Produção & Ganho'),
        CardProducaoDetalhado(titulo: 'GMD Médio', valor: '${calc.gmdNascDesmame.toStringAsFixed(3)} kg/dia', icone: Icons.show_chart_rounded, cor: Colors.blue, status: calc.getStatusGMD(), subtitulo: 'Primeira e última pesagem de cada animal', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoGMD()))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CardMetricaSimples(label: 'Taxa Desmame', valor: '${calc.taxaDesmame.toStringAsFixed(1)}%', meta: '> 85%', status: calc.getStatusDesmame(), icone: Icons.child_care, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())))),
          const SizedBox(width: 12),
          Expanded(child: CardMetricaSimples(label: 'Leite / Dia', valor: '${calc.mediaLeiteDia.toStringAsFixed(1)} L', meta: 'Média Vaca', status: StatusIndicador.neutro, icone: Icons.water_drop, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoLeite())))),
        ]).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 32),
        const TituloSecao('Saúde do Rebanho'),
        CardSanidade(taxaMortalidade: calc.taxaMortalidade, status: calc.getStatusMortalidade(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoMortalidade()))).animate().slideY(begin: 0.2, end: 0, delay: 400.ms),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CardMetricaSimples(label: 'Pesagens', valor: '${provedor.pesagens.length} registros', meta: 'Total registrado', status: StatusIndicador.neutro, icone: Icons.monitor_weight, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoPesagem())))),
          const SizedBox(width: 12),
          Expanded(child: CardMetricaSimples(label: 'Eventos Reprod.', valor: '${provedor.eventosReprodutivos.length} eventos', meta: 'Total registrado', status: StatusIndicador.neutro, icone: Icons.favorite_border, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())))),
        ]).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
        Center(child: Text('Dados baseados em ${animaisFiltrados.length} animais filtrados.', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12))),
        const SizedBox(height: 80),
      ]),
    );
  }
}
