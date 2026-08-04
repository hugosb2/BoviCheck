import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../provedores/provedor_fazenda.dart';

import '../10_formularios/form_pesagem.dart';
import '../10_formularios/form_sanitario.dart';
import '../10_formularios/form_reprodutivo.dart';
import '../10_formularios/form_leite.dart';
import '../10_formularios/form_abate.dart';
import '../8_rebanho/form_animal.dart';
import '../8_rebanho/tela_lista_animais.dart';
import '../9_piquetes/form_piquete.dart';
import '../9_piquetes/tela_lista_piquetes.dart';
import '../5_ia_consultor/tela_ia_consultor.dart';

import 'widgets/gaveta_menu.dart';

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
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (!temFazenda) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cottage_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 24),
                Text(
                  'Nenhuma fazenda selecionada',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Abra o menu e selecione ou cadastre uma fazenda.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provedor.totalPiquetes == 0) {
      return _construirOnboardingPiquete(context, theme, provedor);
    }

    if (provedor.totalAnimais == 0) {
      return _construirOnboardingAnimal(context, theme, provedor);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const GavetaMenu(),
      appBar: const AppBarPadrao(
        titulo: 'BoviCheck',
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalhoFazenda(theme, provedor).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 28),

              const _SecaoTitulo(titulo: 'Resumo do Rebanho'),
              const SizedBox(height: 16),

              _heroTotalRebanho(theme, provedor),

              const SizedBox(height: 16),

              _gridSecundario(theme, provedor),

              const SizedBox(height: 28),

              _cardInsightIA(theme, provedor),

              const SizedBox(height: 32),

              const _SecaoTitulo(titulo: 'Ações Rápidas'),
              const SizedBox(height: 16),

              _gridAgesRapidas(context, theme),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: BotaoFlutuanteBovi(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAnimal())),
        label: 'Novo Animal',
        icone: Icons.add_rounded,
      ),
    );
  }

  Widget _cabecalhoFazenda(ThemeData theme, ProvedorFazenda provedor) {
    final propriedade = provedor.propriedadeAtiva!;
    final nome = propriedade.nomeFazenda.isEmpty ? 'BoviCheck' : propriedade.nomeFazenda;
    final iniciais = nome.length >= 2
        ? nome.substring(0, 2).toUpperCase()
        : nome[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    iniciais,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propriedade.nomeFazenda,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${propriedade.cidade}, ${propriedade.estado}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.waving_hand_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Olá, ${propriedade.nomeProprietario.split(' ').first}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroTotalRebanho(ThemeData theme, ProvedorFazenda provedor) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaListaAnimais())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.75),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: SvgPicture.asset(
                IconesApp.iconAnimalSvg,
                width: 36,
                height: 36,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total do Rebanho',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provedor.totalAnimais.toString(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.7), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _gridSecundario(ThemeData theme, ProvedorFazenda provedor) {
    return Row(
      children: [
        Expanded(
          child: _cardStatPequeno(
            theme: theme,
            titulo: 'Piquetes',
            valor: provedor.totalPiquetes.toString(),
            icone: IconesApp.piquete,
            cor: Colors.orange.shade700,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaListaPiquetes())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardStatPequeno(
            theme: theme,
            titulo: 'Leite (mês)',
            valor: '${provedor.totalLeiteMes.toStringAsFixed(0)} L',
            icone: IconesApp.leite,
            cor: Colors.cyan.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardStatPequeno(
            theme: theme,
            titulo: 'GMD Médio',
            valor: '${provedor.mediaGMD.toStringAsFixed(2)} kg',
            icone: IconesApp.peso,
            cor: Colors.teal.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardStatPequeno(
            theme: theme,
            titulo: 'Alertas',
            valor: provedor.totalAnimaisDoentes.toString(),
            icone: IconesApp.iaAtencao,
            cor: provedor.totalAnimaisDoentes > 0 ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _cardStatPequeno({
    required ThemeData theme,
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cor.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 8),
            Text(
              valor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardInsightIA(ThemeData theme, ProvedorFazenda provedor) {
    final temAlerta = provedor.totalAnimaisDoentes > 0;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaIAConsultor())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: temAlerta
              ? Colors.red.shade50
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: temAlerta
                ? Colors.red.shade200
                : theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: temAlerta ? Colors.red : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (temAlerta ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                temAlerta ? Icons.warning_rounded : Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consultor IA',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: temAlerta ? Colors.red.shade700 : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    temAlerta
                        ? '${provedor.totalAnimaisDoentes} animal(is) com alerta de saúde'
                        : 'Rebanho saudável! GMD médio de ${provedor.mediaGMD.toStringAsFixed(2)} kg.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: temAlerta ? Colors.red.shade800 : theme.colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _gridAgesRapidas(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _botaoAcao(context, 'Pesagem', IconesApp.peso, Colors.indigo, const FormPesagem())),
            const SizedBox(width: 12),
            Expanded(child: _botaoAcao(context, 'Saúde', IconesApp.vacina, Colors.red, const FormSanitario())),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _botaoAcao(context, 'Reprodução', IconesApp.reproducao, Colors.pink, const FormReprodutivo())),
            const SizedBox(width: 12),
            Expanded(child: _botaoAcao(context, 'Leite', IconesApp.leite, Colors.blue, const FormLeite())),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _botaoAcao(context, 'Abate', Icons.restaurant, Colors.brown, const FormAbate())),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _botaoAcao(BuildContext context, String label, IconData icone, Color cor, Widget destino) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withValues(alpha: 0.2), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icone, color: cor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cor.withValues(alpha: 0.4), size: 22),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }

  Scaffold _construirOnboardingPiquete(BuildContext context, ThemeData theme, ProvedorFazenda provedor) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const GavetaMenu(),
      appBar: const AppBarPadrao(titulo: 'BoviCheck'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconesApp.piquete, size: 100, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 32),
            Text(
              'Crie seu primeiro piquete',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Piquetes organizam seus animais por categoria, como 'Matrizes', 'Bezerros' ou 'Confinamento'.\n\nCrie ao menos um piquete para começar.",
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPiquete()));
                  if (!context.mounted) return;
                  await context.read<ProvedorFazenda>().carregarPropriedades();
                },
                icon: const Icon(Icons.add),
                label: const Text('Criar Piquete', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Scaffold _construirOnboardingAnimal(BuildContext context, ThemeData theme, ProvedorFazenda provedor) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const GavetaMenu(),
      appBar: const AppBarPadrao(titulo: 'BoviCheck'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              IconesApp.iconAnimalSvg,
              width: 100,
              height: 100,
              colorFilter: ColorFilter.mode(theme.colorScheme.primary.withValues(alpha: 0.3), BlendMode.srcIn),
            ),
            const SizedBox(height: 32),
            Text(
              'Cadastre seu primeiro animal',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Agora cadastre os animais do seu rebanho. Informe brinco, nome, raça, data de nascimento e muito mais.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAnimal()));
                  if (!context.mounted) return;
                  await context.read<ProvedorFazenda>().carregarPropriedades();
                },
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Animal', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  const _SecaoTitulo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}


