import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../estilos/tema.dart';
import '../8_rebanho/form_animal.dart';
import 'widgets/gaveta_menu.dart';
import 'widgets/cabecalho_fazenda.dart';
import 'widgets/hero_total_rebanho.dart';
import 'widgets/grid_secundario.dart';
import 'widgets/card_insight_ia.dart';
import 'widgets/grid_acoes_rapidas.dart';
import 'widgets/onboarding_widgets.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});
  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProvedorFazenda>().carregarPropriedades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final bool temFazenda = provedor.propriedadeAtiva != null;
    final bool isLoading = provedor.isLoading;

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (!temFazenda) {
      return Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cottage_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text('Nenhuma fazenda selecionada', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Abra o menu e selecione ou cadastre uma fazenda.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ]))),
      );
    }
    if (provedor.totalPiquetes == 0) return const OnboardingPiquete();
    if (provedor.totalAnimais == 0) return const OnboardingAnimal();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const GavetaMenu(),
      appBar: const AppBarPadrao(titulo: 'BoviCheck'),
      body: RefreshIndicator(
        onRefresh: () async {
          final id = provedor.propriedadeAtiva!.id;
          await provedor.carregarPropriedades();
          await provedor.carregarAnimais(id);
          await provedor.carregarPiquetes(id);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CabecalhoFazenda(propriedade: provedor.propriedadeAtiva!).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 28),
            const SecaoTitulo(titulo: 'Resumo do Rebanho'),
            const SizedBox(height: 16),
            HeroTotalRebanho(totalAtivos: provedor.totalAnimaisAtivos, totalGeral: provedor.totalAnimais),
            const SizedBox(height: 16),
            GridSecundario(totalPiquetes: provedor.totalPiquetes, totalLeiteMes: provedor.totalLeiteMes, mediaGMD: provedor.mediaGMD, totalDoentes: provedor.totalAnimaisDoentes),
            const SizedBox(height: 28),
            CardInsightIA(totalDoentes: provedor.totalAnimaisDoentes, mediaGMD: provedor.mediaGMD).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            const SecaoTitulo(titulo: 'Ações Rápidas'),
            const SizedBox(height: 16),
            const GridAcoesRapidas(),
            const SizedBox(height: 40),
          ]),
        ),
      ),
      floatingActionButton: BotaoFlutuanteBovi(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAnimal())), label: 'Novo Animal', icone: Icons.add_rounded),
    );
  }
}

class SecaoTitulo extends StatelessWidget {
  final String titulo;
  const SecaoTitulo({super.key, required this.titulo});
  @override
  Widget build(BuildContext context) => Text(titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800));
}
