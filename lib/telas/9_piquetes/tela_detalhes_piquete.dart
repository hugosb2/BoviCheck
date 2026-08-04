import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../modelos/piquete.dart';
import '../../provedores/provedor_fazenda.dart';
import '../8_rebanho/tela_detalhes_animal.dart';
import '../10_formularios/form_pesagem.dart';
import '../10_formularios/form_sanitario.dart';
import '../8_rebanho/form_animal.dart';
import 'form_piquete.dart';

class TelaDetalhesPiquete extends StatefulWidget {
  final Piquete piquete;

  const TelaDetalhesPiquete({super.key, required this.piquete});

  @override
  State<TelaDetalhesPiquete> createState() => _TelaDetalhesPiqueteState();
}

class _TelaDetalhesPiqueteState extends State<TelaDetalhesPiquete> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final piqueteAtual = provedor.piquetes.firstWhere(
      (p) => p.id == widget.piquete.id,
      orElse: () => widget.piquete,
    );
    final animaisDoPiquete =
        provedor.animais.where((a) => a.loteId == piqueteAtual.id).toList();
    final total = animaisDoPiquete.length;
    final machos = animaisDoPiquete.where((a) => a.sexo == 'M').length;
    final femeas = animaisDoPiquete.where((a) => a.sexo == 'F').length;
    final pesoMedio = total > 0
        ? animaisDoPiquete.fold<double>(0.0, (s, a) => s + a.pesoAtualKg) /
            total
        : 0.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarPadrao(titulo: piqueteAtual.nome),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroPiquete(theme, piqueteAtual).animate().fadeIn().scale(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _gridFicha(theme, piqueteAtual),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _gridEstatisticas(theme, total, machos, femeas, pesoMedio),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _blocoAcoes(context, theme, piqueteAtual),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _blocoAnimais(context, theme, animaisDoPiquete),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _heroPiquete(ThemeData theme, Piquete piquete) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        piquete.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        piquete.tipo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconesApp.piquete,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
            if (piquete.descricao.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: Colors.white.withValues(alpha: 0.7), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        piquete.descricao,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gridFicha(ThemeData theme, Piquete piquete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SecaoLabel(texto: 'Ficha Técnica'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _fichaItem(
                theme,
                IconesApp.iconAnimalSvg,
                'Capacidade',
                piquete.capacidade > 0 ? '${piquete.capacidade} cab.' : '—',
                cor: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _fichaItem(
                theme,
                IconesApp.piquete,
                'Área',
                piquete.areaHectares > 0
                    ? '${piquete.areaHectares.toStringAsFixed(1)} ha'
                    : '—',
                cor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _fichaItem(
                theme,
                Icons.agriculture_outlined,
                'Sistema',
                piquete.sistemaProducao,
                cor: Colors.brown,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fichaItem(
      ThemeData theme, dynamic icone, String label, String valor,
      {Color? cor}) {
    final corUsar = cor ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          if (icone is String)
            SvgPicture.asset(
              icone,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(corUsar, BlendMode.srcIn),
            )
          else
            Icon(icone is IconData ? icone : Icons.info_outline,
                color: corUsar, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _gridEstatisticas(
      ThemeData theme, int total, int machos, int femeas, double pesoMedio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SecaoLabel(texto: 'Rebanho'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _cardEstatistica(
                theme: theme,
                valor: '$total',
                label: total == 1 ? 'Animal' : 'Animais',
                cor: theme.colorScheme.primary,
                svgIcone: IconesApp.iconAnimalSvg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _cardEstatistica(
                theme: theme,
                valor: '$machos',
                label: 'Machos',
                cor: Colors.blue,
                icone: Icons.male,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _cardEstatistica(
                theme: theme,
                valor: '$femeas',
                label: 'Fêmeas',
                cor: Colors.pink,
                icone: Icons.female,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _cardEstatistica(
                theme: theme,
                valor: pesoMedio > 0 ? pesoMedio.toStringAsFixed(0) : '—',
                label: 'Méd. Kg',
                cor: Colors.teal,
                icone: IconesApp.peso,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardEstatistica({
    required ThemeData theme,
    required String valor,
    required String label,
    required Color cor,
    IconData? icone,
    String? svgIcone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          if (svgIcone != null)
            SvgPicture.asset(
              svgIcone,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
            )
          else
            Icon(icone, color: cor, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoAcoes(BuildContext context, ThemeData theme, Piquete piquete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SecaoLabel(texto: 'Ações Rápidas'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _botaoAcao(
                context,
                theme,
                icone: Icons.edit_outlined,
                label: 'Editar',
                cor: theme.colorScheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FormPiquete(piqueteExistente: piquete)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _botaoAcao(
                context,
                theme,
                icone: Icons.add,
                label: 'Cadastrar\nAnimal',
                cor: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const FormAnimal()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _botaoAcao(
                context,
                theme,
                icone: Icons.monitor_weight_outlined,
                label: 'Pesagem',
                cor: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormPesagem()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _botaoAcao(
                context,
                theme,
                icone: Icons.medical_services_outlined,
                label: 'Sanitário',
                cor: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormSanitario()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botaoAcao(
    BuildContext context,
    ThemeData theme, {
    required IconData icone,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: cor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blocoAnimais(
      BuildContext context, ThemeData theme, List<dynamic> animais) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SecaoLabel(texto: 'Animais no Piquete'),
            if (animais.isNotEmpty)
              Text(
                '${animais.length} ${animais.length == 1 ? 'registro' : 'registros'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (animais.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  IconesApp.iconAnimalSvg,
                  width: 56,
                  height: 56,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.outline.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum animal neste piquete',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use o menu acima para cadastrar um animal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...animais.asMap().entries.map((entry) {
            final i = entry.key;
            final animal = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _itemAnimal(context, theme, animal)
                  .animate()
                  .fadeIn(delay: (400 + i * 60).ms)
                  .slideX(begin: 0.08, end: 0),
            );
          }),
      ],
    );
  }

  Widget _itemAnimal(BuildContext context, ThemeData theme, dynamic animal) {
    final sexoCor = animal.sexo == 'M' ? Colors.blue : Colors.pink;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaDetalhesAnimal(animal: animal),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  IconesApp.iconAnimalSvg,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.brinco,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((animal.nome ?? '').isNotEmpty)
                      Text(
                        animal.nome,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          animal.categoria,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        if (animal.pesoAtualKg > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.monitor_weight_outlined,
                              size: 12,
                              color: theme.colorScheme.outline),
                          const SizedBox(width: 2),
                          Text(
                            '${animal.pesoAtualKg.toStringAsFixed(0)} kg',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sexoCor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      animal.sexo == 'M' ? Icons.male : Icons.female,
                      size: 14,
                      color: sexoCor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      animal.sexo == 'M' ? 'M' : 'F',
                      style: TextStyle(
                        color: sexoCor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecaoLabel extends StatelessWidget {
  final String texto;
  const _SecaoLabel({required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          texto,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
