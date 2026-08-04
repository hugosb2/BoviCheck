import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../provedores/provedor_fazenda.dart';
import '../10_formularios/form_leite.dart';

class TelaHistoricoLeite extends StatefulWidget {
  const TelaHistoricoLeite({super.key});

  @override
  State<TelaHistoricoLeite> createState() => _TelaHistoricoLeiteState();
}

class _TelaHistoricoLeiteState extends State<TelaHistoricoLeite> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final registros = provedor.producaoLeite;

    if (registros.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Produção de Leite'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop_outlined, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Nenhuma produção registrada', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Registre a produção diária de leite para acompanhar', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 32),
              BotaoPadrao(
                label: 'REGISTRAR LEITE',
                icone: Icons.add,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormLeite())),
              ),
            ],
          ),
        ),
      );
    }

    final mediaGeral = registros.fold(0.0, (s, r) => s + r.litros) / registros.length;

    final meses = <String, List<double>>{};
    for (var r in registros) {
      final chave = DateFormat('MMM/yy').format(r.data);
      meses.putIfAbsent(chave, () => []).add(r.litros);
    }
    final dadosMensais = meses.entries.map((e) {
      final total = e.value.reduce((a, b) => a + b);
      return _DadoMensal(label: e.key, valor: total, media: total / e.value.length);
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Produção de Leite'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroLeite(theme, mediaGeral, registros.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Produção Mensal (Total L)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...dadosMensais.reversed.map((d) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _itemMensal(theme, d),
          ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0)),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormLeite())),
        icon: const Icon(Icons.add),
        label: const Text('LEITE'),
      ),
    );
  }

  Widget _heroLeite(ThemeData theme, double media, int totalRegistros) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.blue.shade200, blurRadius: 20, offset: const Offset(0, 8))],
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
                  child: const Icon(Icons.water_drop, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Média Geral', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('$totalRegistros registros', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(media.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const Padding(padding: EdgeInsets.only(bottom: 6), child: Text(' L', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600))),
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
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Média: ${d.media.toStringAsFixed(1)} L', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          Text('${d.valor.toStringAsFixed(0)} L', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _DadoMensal {
  final String label;
  final double valor;
  final double media;
  _DadoMensal({required this.label, required this.valor, required this.media});
}
