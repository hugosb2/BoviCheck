import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../estilos/tema.dart';

class TelaHistoricoMortalidade extends StatefulWidget {
  const TelaHistoricoMortalidade({super.key});

  @override
  State<TelaHistoricoMortalidade> createState() => _TelaHistoricoMortalidadeState();
}

class _TelaHistoricoMortalidadeState extends State<TelaHistoricoMortalidade> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final animais = provedor.animais;

    if (animais.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Taxa de Mortalidade'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety_outlined, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Nenhum animal cadastrado', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Cadastre animais e registre óbitos para acompanhar', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    final obitos = animais.where((a) => !a.isAtivo && a.dataObito != null).length;
    final taxaGeral = obitos / animais.length * 100;

    final agora = DateTime.now();
    final dadosAnuais = <_DadoAnual>[];
    for (var i = 3; i >= 0; i--) {
      final ano = agora.year - i;
      final inicioAno = DateTime(ano, 1, 1);
      final fimAno = DateTime(ano, 12, 31);
      final obitosAno = animais.where((a) =>
        !a.isAtivo && a.dataObito != null && !a.dataObito!.isBefore(inicioAno) && !a.dataObito!.isAfter(fimAno)
      ).length;
      final totalAno = animais.where((a) => !a.dataNascimento.isAfter(fimAno)).length;
      dadosAnuais.add(_DadoAnual(
        ano: ano.toString(), valor: totalAno > 0 ? obitosAno / totalAno * 100 : 0.0, obitos: obitosAno, total: totalAno,
      ));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Taxa de Mortalidade'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _heroMortalidade(theme, taxaGeral, obitos),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Evolução Anual', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...dadosAnuais.map((d) {
            final cor = d.valor <= 3 ? Colors.green : (d.valor <= 5 ? Colors.orange : Colors.red);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: _itemAnual(theme, d, cor).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0),
            );
          }),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Metas', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Row(children: [Icon(Icons.circle, size: 8, color: Colors.green), SizedBox(width: 8), Text('Ideal: < 3%')]),
                const Row(children: [Icon(Icons.circle, size: 8, color: Colors.orange), SizedBox(width: 8), Text('Atenção: 3 - 5%')]),
                const Row(children: [Icon(Icons.circle, size: 8, color: Colors.red), SizedBox(width: 8), Text('Ruim: > 5%')]),
              ]),
            ).animate().fadeIn(delay: 200.ms),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _heroMortalidade(ThemeData theme, double taxa, int obitos) {
    final cor = taxa <= 3 ? Colors.green : (taxa <= 5 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor.shade700, cor.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: cor.shade200, blurRadius: 20, offset: const Offset(0, 8))],
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
                  child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Taxa de Mortalidade', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('$obitos óbitos registrados', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Text('${taxa.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemAnual(ThemeData theme, _DadoAnual d, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.ano, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${d.obitos} óbitos de ${d.total}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          Text('${d.valor.toStringAsFixed(1)}%', style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _DadoAnual {
  final String ano;
  final double valor;
  final int obitos;
  final int total;
  _DadoAnual({required this.ano, required this.valor, required this.obitos, required this.total});
}
