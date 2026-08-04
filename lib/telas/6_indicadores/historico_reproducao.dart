import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../modelos/eventos/evento_reprodutivo.dart';
import '../../modelos/animal.dart';
import '../8_rebanho/tela_detalhes_animal.dart';
import '../10_formularios/form_reprodutivo.dart';

class TelaHistoricoReproducao extends StatefulWidget {
  const TelaHistoricoReproducao({super.key});

  @override
  State<TelaHistoricoReproducao> createState() => _TelaHistoricoReproducaoState();
}

class _TelaHistoricoReproducaoState extends State<TelaHistoricoReproducao> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final eventos = provedor.eventosReprodutivos;
    final animais = provedor.animais;

    if (eventos.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Histórico Reprodutivo'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Nenhum evento reprodutivo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Registre o primeiro evento para acompanhar', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
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

    final nascimentos = eventos.where((e) => e.tipo == 'Parto').length;
    final femeas = animais.where((a) => a.sexo == 'F' && a.calcularIdadeMeses() >= 24).length;
    final natalidade = femeas > 0 ? (nascimentos / femeas) * 100 : 0.0;

    final eventosOrd = List<EventoReprodutivo>.from(eventos)..sort((a, b) => b.data.compareTo(a.data));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Histórico Reprodutivo'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroReproducao(theme, natalidade, nascimentos, femeas),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Últimos Eventos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...eventosOrd.take(50).map((e) {
            final animal = animais.cast<Animal?>().firstWhere(
              (a) => a?.id == e.animalId,
              orElse: () => null,
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: _itemEvento(context, theme, e, animal).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0),
            );
          }),
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

  Widget _heroReproducao(ThemeData theme, double natalidade, int nascimentos, int femeas) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade700, Colors.pink.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.pink.shade200, blurRadius: 20, offset: const Offset(0, 8))],
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
                      const Text('Natalidade Geral', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('$nascimentos nascimentos • ${nascimentos > 0 ? "Baseado em $femeas fêmeas" : "Sem dados"}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                ),
                Text('${natalidade.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemEvento(BuildContext context, ThemeData theme, EventoReprodutivo e, Animal? animal) {
    final brinco = animal?.brinco ?? '?';
    final nome = animal?.nome;
    Color corTipo;
    IconData icone;
    switch (e.tipo) {
      case 'Parto':
        corTipo = Colors.green;
        icone = Icons.child_care;
        break;
      case 'Inseminação (IA)':
      case 'Monta Natural':
        corTipo = Colors.blue;
        icone = Icons.biotech;
        break;
      case 'Diagnóstico Gestação':
        corTipo = Colors.purple;
        icone = Icons.pregnant_woman;
        break;
      case 'Desmame':
        corTipo = Colors.orange;
        icone = Icons.child_friendly;
        break;
      case 'Aborto':
        corTipo = Colors.red;
        icone = Icons.warning_amber_rounded;
        break;
      case 'Cio':
        corTipo = Colors.pink;
        icone = Icons.favorite;
        break;
      default:
        corTipo = Colors.grey;
        icone = Icons.event_note;
    }
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
                decoration: BoxDecoration(color: corTipo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icone, color: corTipo, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Brinco $brinco', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (nome != null) Text(nome, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(DateFormat('dd/MM/yyyy').format(e.data), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: corTipo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(e.tipo, style: TextStyle(color: corTipo, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  if (e.resultado != null) ...[
                    const SizedBox(height: 4),
                    Text(e.resultado!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
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
