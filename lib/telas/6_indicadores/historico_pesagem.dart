import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../modelos/eventos/pesagem.dart';
import '../../modelos/animal.dart';
import '../8_rebanho/tela_detalhes_animal.dart';
import '../10_formularios/form_pesagem.dart';

class TelaHistoricoPesagem extends StatefulWidget {
  const TelaHistoricoPesagem({super.key});

  @override
  State<TelaHistoricoPesagem> createState() => _TelaHistoricoPesagemState();
}

class _TelaHistoricoPesagemState extends State<TelaHistoricoPesagem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final pesagens = provedor.pesagens;
    final animais = provedor.animais;

    final animaisAtivos = animais.where((a) => a.isAtivo).toList();
    final pesoMedio = animaisAtivos.isEmpty ? 0.0 : animaisAtivos.fold(0.0, (s, a) => s + a.pesoAtualKg) / animaisAtivos.length;

    if (pesagens.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Histórico de Pesagens'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_weight_outlined, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Nenhuma pesagem registrada', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Registre a primeira pesagem para acompanhar', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 32),
              BotaoPadrao(
                label: 'REGISTRAR PESO',
                icone: Icons.add,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPesagem())),
              ),
            ],
          ),
        ),
      );
    }

    final pesagensOrd = List<Pesagem>.from(pesagens)..sort((a, b) => b.data.compareTo(a.data));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Histórico de Pesagens'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroPesagem(theme, pesoMedio, animaisAtivos.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Últimas Pesagens', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...pesagensOrd.take(50).map((p) {
            final animal = animais.cast<Animal?>().firstWhere(
              (a) => a?.id == p.animalId,
              orElse: () => null,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: _itemPesagem(context, theme, p, animal).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0),
            );
          }),
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

  Widget _heroPesagem(ThemeData theme, double pesoMedio, int totalAnimais) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.indigo.shade200, blurRadius: 20, offset: const Offset(0, 8))],
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
                  child: const Icon(Icons.monitor_weight, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Peso Médio Atual', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('$totalAnimais animais ativos', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Text('${pesoMedio.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemPesagem(BuildContext context, ThemeData theme, Pesagem p, Animal? animal) {
    final brinco = animal?.brinco ?? '?';
    final nome = animal?.nome;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: animal != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesAnimal(animal: animal))) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.monitor_weight, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Brinco $brinco', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (nome != null) Text(nome, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(DateFormat('dd/MM/yyyy').format(p.data), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${p.pesoKg.toStringAsFixed(1)} kg', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  if (p.etapa != 'Geral')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(p.etapa, style: TextStyle(color: Colors.indigo.shade300, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  if (p.observacao != null && p.observacao!.isNotEmpty)
                    Text(p.observacao!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline.withValues(alpha: 0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
