import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../provedores/provedor_fazenda.dart';
import '../10_formularios/form_reprodutivo.dart';

class TelaHistoricoIEP extends StatefulWidget {
  const TelaHistoricoIEP({super.key});

  @override
  State<TelaHistoricoIEP> createState() => _TelaHistoricoIEPState();
}

class _TelaHistoricoIEPState extends State<TelaHistoricoIEP> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final eventos = provedor.eventosReprodutivos;
    final partos = eventos.where((e) => e.tipo == 'Parto').toList();

    // Agrupa partos por animal e verifica se algum animal tem 2+ partos.
    final Map<String, List<DateTime>> partosPorVaca = {};
    for (var e in partos) {
      partosPorVaca.putIfAbsent(e.animalId, () => []).add(e.data);
    }
    final possuiIep = partosPorVaca.values.any((datas) => datas.length >= 2);

    if (!possuiIep) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Intervalo Entre Partos'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Dados insuficientes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('São necessários pelo menos 2 partos\ndo mesmo animal para calcular o IEP', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              BotaoPadrao(
                label: 'REGISTRAR EVENTO',
                icone: Icons.add,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormReprodutivo())),
              ),
            ],
          ),
        ),
      );
    }

    // Agrupa partos por animal e calcula IEPs
    final ieps = <double>[];
    final meses = <String, List<double>>{};
    partosPorVaca.forEach((id, datas) {
      if (datas.length < 2) return;
      datas.sort();
      for (int i = 0; i < datas.length - 1; i++) {
        final diff = datas[i + 1].difference(datas[i]).inDays;
        if (diff > 250) {
          final iepMeses = diff / 30.44;
          ieps.add(iepMeses);
          meses.putIfAbsent(DateFormat('MMM/yy').format(datas[i + 1]), () => []).add(iepMeses);
        }
      }
    });

    final dadosMensais = meses.entries.map((e) {
      final media = e.value.reduce((a, b) => a + b) / e.value.length;
      return _DadoMensal(label: e.key, valor: media);
    }).toList();

    final iepMedio = ieps.isEmpty ? 0.0 : ieps.reduce((a, b) => a + b) / ieps.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Intervalo Entre Partos'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroIEP(theme, iepMedio, partos.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Evolução Mensal (meses)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...dadosMensais.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                      child: Text('Sem dados suficientes para exibir', style: TextStyle(color: theme.colorScheme.outline)),
                    ),
                  ),
                ]
              : dadosMensais.reversed.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: _itemMensal(theme, d),
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0)),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormReprodutivo())),
        icon: const Icon(Icons.add),
        label: const Text('EVENTO'),
      ),
    );
  }

  Widget _heroIEP(ThemeData theme, double iepMedio, int totalPartos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.purple.shade200, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IEP Médio', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('$totalPartos partos registrados', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(iepMedio.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const Padding(padding: EdgeInsets.only(bottom: 6), child: Text(' meses', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMensal(ThemeData theme, _DadoMensal d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(d.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${d.valor.toStringAsFixed(1)} meses', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _DadoMensal {
  final String label;
  final double valor;
  _DadoMensal({required this.label, required this.valor});
}
