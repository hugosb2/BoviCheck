import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../modelos/eventos/pesagem.dart';
import '../../estilos/tema.dart';
import '../10_formularios/form_pesagem.dart';

class TelaHistoricoGMD extends StatefulWidget {
  const TelaHistoricoGMD({super.key});

  @override
  State<TelaHistoricoGMD> createState() => _TelaHistoricoGMDState();
}

class _TelaHistoricoGMDState extends State<TelaHistoricoGMD> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final pesagens = provedor.pesagens;

    if (pesagens.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Ganho Médio Diário'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Nenhuma pesagem registrada', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Registre pelo menos 2 pesagens por animal\npara calcular o GMD', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              BotaoPadrao(
                label: 'REGISTRAR PESAGEM',
                icone: Icons.add,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPesagem())),
              ),
            ],
          ),
        ),
      );
    }

    // Agrupa pesagens por animal e ordena por data
    final Map<String, List<Pesagem>> porAnimal = {};
    for (var p in pesagens) {
      porAnimal.putIfAbsent(p.animalId, () => []).add(p);
    }

    // Calcula GMD para cada animal com 2+ pesagens
    final gmds = <double>[];
    final gmdsPorMes = <String, List<double>>{};

    for (var lista in porAnimal.values) {
      if (lista.length < 2) continue;
      lista.sort((a, b) => a.data.compareTo(b.data));
      final primeira = lista.first;
      final ultima = lista.last;
      final dias = ultima.data.difference(primeira.data).inDays;
      if (dias < 7) continue;
      final ganho = ultima.pesoKg - primeira.pesoKg;
      final gmd = ganho / dias;

      gmds.add(gmd);

      final chave = DateFormat('MMM/yy').format(ultima.data);
      gmdsPorMes.putIfAbsent(chave, () => []).add(gmd);
    }

    final dadosMensais = gmdsPorMes.entries.map((e) {
      final media = e.value.reduce((a, b) => a + b) / e.value.length;
      return _DadoMensal(label: e.key, valor: media * 1000, sortKey: e.key);
    }).toList();

    final gmdMedio = gmds.isEmpty ? 0.0 : gmds.reduce((a, b) => a + b) / gmds.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Ganho Médio Diário'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroGMD(theme, gmdMedio, gmds.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Evolução Mensal (g/dia)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                      child: Text('Sem dados suficientes para calcular GMD', style: TextStyle(color: theme.colorScheme.outline)),
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPesagem())),
        icon: const Icon(Icons.add),
        label: const Text('PESAGEM'),
      ),
    );
  }

  Widget _heroGMD(ThemeData theme, double gmdMedio, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.orange.shade200, blurRadius: 20, offset: const Offset(0, 8))],
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
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GMD Médio', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('$total animais com GMD calculado', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text((gmdMedio * 1000).toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const Padding(padding: EdgeInsets.only(bottom: 6), child: Text(' g/dia', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))),
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
    final cor = d.valor >= 0 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(d.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(
            '${d.valor.toStringAsFixed(0)} g/dia',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _DadoMensal {
  final String label;
  final double valor;
  final String sortKey;
  _DadoMensal({required this.label, required this.valor, this.sortKey = ''});
}
