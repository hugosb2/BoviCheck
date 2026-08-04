import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/tema.dart';
import '../../estilos/cores.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/calculadora_indicadores.dart';
import 'historico_reproducao.dart';
import 'historico_leite.dart';
import 'historico_pesagem.dart';
import 'historico_gmd.dart';
import 'historico_iep.dart';
import 'historico_mortalidade.dart';

class TelaIndicadores extends StatefulWidget {
  const TelaIndicadores({super.key});

  @override
  State<TelaIndicadores> createState() => _TelaIndicadoresState();
}

class _TelaIndicadoresState extends State<TelaIndicadores> {
  DateTimeRange _periodoSelecionado = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 365)),
    end: DateTime.now(),
  );
  String? _loteSelecionadoId;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva != null) {
          if (provedor.animais.isEmpty) {
            await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);
          }
        }
      } catch (_) {}
      if (mounted) setState(() => _inicializado = true);
    });
  }

  void _atualizarPeriodo(int dias) {
    setState(() {
      _periodoSelecionado = DateTimeRange(
        start: DateTime.now().subtract(Duration(days: dias)),
        end: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();

    if (!_inicializado) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Performance'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provedor.propriedadeAtiva == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const AppBarPadrao(titulo: 'Performance'),
        body: const Center(
          child: Text('Nenhuma fazenda selecionada.'),
        ),
      );
    }

    // --- LÃ“GICA DE FILTRAGEM ---
    final animaisFiltrados = _loteSelecionadoId == null
        ? provedor.animais
        : provedor.animais.where((a) => a.loteId == _loteSelecionadoId).toList();

    final idsAnimais = animaisFiltrados.map((a) => a.id).toSet();

    final calc = CalculadoraIndicadores(
      animais: animaisFiltrados,
      pesagens:
          provedor.pesagens.where((e) => idsAnimais.contains(e.animalId)).toList(),
      reprodutivos: provedor.eventosReprodutivos
          .where((e) => idsAnimais.contains(e.animalId))
          .toList(),
      leite: provedor.producaoLeite
          .where((e) => idsAnimais.contains(e.animalId))
          .toList(),
      inicio: _periodoSelecionado.start,
      fim: _periodoSelecionado.end,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(
        titulo: 'Performance',
      ),
      body: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 2. Filtros
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown Piquete Estilizado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _loteSelecionadoId,
                          hint: const Text('Todos os Piquetes'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Rebanho Geral')),
                            ...provedor.piquetes.map((l) => DropdownMenuItem(
                                value: l.id, child: Text(l.nome))),
                          ],
                          onChanged: (v) =>
                              setState(() => _loteSelecionadoId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Chips de Data
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _PeriodoChip('30 Dias', 30, _periodoSelecionado,
                              (d) => _atualizarPeriodo(d)),
                          _PeriodoChip('6 Meses', 180, _periodoSelecionado,
                              (d) => _atualizarPeriodo(d)),
                          _PeriodoChip('1 Ano', 365, _periodoSelecionado,
                              (d) => _atualizarPeriodo(d)),
                          _PeriodoChip('Tudo', 3650, _periodoSelecionado,
                              (d) => _atualizarPeriodo(d)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- SEÃ‡ÃƒO 1: DESTAQUES REPRODUTIVOS (GRÃFICOS) ---
                const _TituloSecao('EficiÃªncia Reprodutiva'),
                Row(
                  children: [
                    Expanded(
                      child: _CardCircular(
                        titulo: 'Natalidade',
                        porcentagem: calc.taxaNatalidade,
                        meta: 80,
                        cor: Colors.pink,
                        tooltip: 'Nascimentos / FÃªmeas Aptas',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardCircular(
                        titulo: 'Prenhez',
                        porcentagem: calc.taxaPrenhez,
                        meta: 85,
                        cor: Colors.purple,
                        tooltip: 'DiagnÃ³sticos Positivos',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())),
                      ),
                    ),
                  ],
                ).animate().scale(duration: 400.ms),

                const SizedBox(height: 12),

                // Dados SecundÃ¡rios de ReproduÃ§Ã£o
                Row(
                  children: [
                    Expanded(
                      child: _CardMetricaSimples(
                        label: 'IEP (Meses)',
                        valor: calc.iepMeses.toStringAsFixed(1),
                        meta: 'Meta: 12-14',
                        status: calc.getStatusIEP(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoIEP())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardMetricaSimples(
                        label: '1Âº Parto (Meses)',
                        valor:
                            calc.idadePrimeiroPartoMeses.toStringAsFixed(1),
                        meta: 'Meta: < 30',
                        status: calc.getStatusIdadeParto(),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                // --- SEÃ‡ÃƒO 2: PRODUÃ‡ÃƒO (CARDS GRANDES) ---
                const _TituloSecao('ProduÃ§Ã£o & Ganho'),

                _CardProducaoDetalhado(
                  titulo: 'GMD MÃ©dio',
                  valor: '${calc.gmdNascDesmame.toStringAsFixed(3)} kg/dia',
                  icone: Icons.show_chart_rounded,
                  cor: Colors.blue,
                  status: calc.getStatusGMD(),
                  subtitulo: 'Primeira e Ãºltima pesagem de cada animal',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoGMD())),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _CardMetricaSimples(
                        label: 'Taxa Desmame',
                        valor: '${calc.taxaDesmame.toStringAsFixed(1)}%',
                        meta: '> 85%',
                        status: calc.getStatusDesmame(),
                        icone: Icons.child_care,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardMetricaSimples(
                        label: 'Leite / Dia',
                        valor: '${calc.mediaLeiteDia.toStringAsFixed(1)} L',
                        meta: 'MÃ©dia Vaca',
                        status: StatusIndicador.neutro,
                        icone: Icons.water_drop,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoLeite())),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // --- SEÃ‡ÃƒO 3: SANIDADE (ALERTAS) ---
                const _TituloSecao('SaÃºde do Rebanho'),

                _CardSanidade(
                  taxaMortalidade: calc.taxaMortalidade,
                  status: calc.getStatusMortalidade(),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoMortalidade())),
                ).animate().slideY(begin: 0.2, end: 0, delay: 400.ms),

                const SizedBox(height: 12),

                // --- SEÃ‡ÃƒO 4: PRODUÃ‡ÃƒO DE LEITE E PESAGENS ---
                Row(
                  children: [
                    Expanded(
                      child: _CardMetricaSimples(
                        label: 'Pesagens',
                        valor: '${provedor.pesagens.length} registros',
                        meta: 'Total registrado',
                        status: StatusIndicador.neutro,
                        icone: Icons.monitor_weight,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoPesagem())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardMetricaSimples(
                        label: 'Eventos Reprod.',
                        valor: '${provedor.eventosReprodutivos.length} eventos',
                        meta: 'Total registrado',
                        status: StatusIndicador.neutro,
                        icone: Icons.favorite_border,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoReproducao())),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'Dados baseados em ${animaisFiltrados.length} animais filtrados.',
                    style: TextStyle(
                        color: theme.colorScheme.outline, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

// ============================================================================
// WIDGETS DE UI
// ============================================================================

class _TituloSecao extends StatelessWidget {
  final String text;
  const _TituloSecao(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CardCircular extends StatelessWidget {
  final String titulo;
  final double porcentagem;
  final double meta;
  final Color cor;
  final String tooltip;
  final VoidCallback? onTap;

  const _CardCircular({
    required this.titulo,
    required this.porcentagem,
    required this.meta,
    required this.cor,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentNormalizado = (porcentagem / 100).clamp(0.0, 1.0);
    final atingiuMeta = porcentagem >= meta;

    Widget card = Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (atingiuMeta)
                  const Icon(Icons.star, size: 16, color: Colors.amber)
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: percentNormalizado,
                    strokeWidth: 12,
                    backgroundColor: cor.withValues(alpha: 0.1),
                    color: cor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${porcentagem.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text('Meta: ${meta.toInt()}%',
                        style: TextStyle(
                            fontSize: 10, color: theme.colorScheme.outline)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      );
    }
    return card;
  }
}

class _CardMetricaSimples extends StatelessWidget {
  final String label;
  final String valor;
  final String meta;
  final StatusIndicador status;
  final IconData? icone;
  final VoidCallback? onTap;

  const _CardMetricaSimples({
    required this.label,
    required this.valor,
    required this.meta,
    required this.status,
    this.icone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color corStatus = _getCorStatus(status);

    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, size: 16, color: Colors.grey),
                const SizedBox(width: 6)
              ],
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
              Icon(Icons.circle, size: 8, color: corStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(valor,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(meta,
              style: TextStyle(
                  fontSize: 11, color: corStatus, fontWeight: FontWeight.w500)),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      );
    }
    return card;
  }
}

class _CardProducaoDetalhado extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final StatusIndicador status;
  final String subtitulo;
  final VoidCallback? onTap;

  const _CardProducaoDetalhado({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    required this.status,
    required this.subtitulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor.withValues(alpha: 0.1), theme.colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitulo,
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(valor,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 8),
                    _ChipStatus(status: status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      );
    }
    return card;
  }
}

class _CardSanidade extends StatelessWidget {
  final double taxaMortalidade;
  final StatusIndicador status;
  final VoidCallback? onTap;

  const _CardSanidade({required this.taxaMortalidade, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRuim = status == StatusIndicador.ruim;

    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRuim
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(isRuim ? Icons.warning_amber_rounded : Icons.health_and_safety,
              color:
                  isRuim ? theme.colorScheme.error : theme.colorScheme.primary,
              size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taxa de Mortalidade',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isRuim
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer)),
                Text(
                    isRuim
                        ? 'AtenÃ§Ã£o! Taxa acima do aceitÃ¡vel.'
                        : 'Dentro dos padrÃµes esperados.',
                    style: TextStyle(
                        fontSize: 12,
                        color: (isRuim
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onPrimaryContainer)
                            .withValues(alpha: 0.8))),
              ],
            ),
          ),
          Text(
            '${taxaMortalidade.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color:
                  isRuim ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      );
    }
    return card;
  }
}

class _ChipStatus extends StatelessWidget {
  final StatusIndicador status;
  const _ChipStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (status) {
      case StatusIndicador.bom:
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case StatusIndicador.atencao:
        icon = Icons.remove;
        color = Colors.orange;
        break;
      case StatusIndicador.ruim:
        icon = Icons.arrow_downward;
        color = Colors.red;
        break;
      case StatusIndicador.neutro:
        icon = Icons.horizontal_rule;
        color = Colors.grey;
        break;
    }
    return Icon(icon, color: color, size: 18);
  }
}

class _PeriodoChip extends StatelessWidget {
  final String label;
  final int dias;
  final DateTimeRange atual;
  final Function(int) onSelected;

  const _PeriodoChip(this.label, this.dias, this.atual, this.onSelected);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = atual.end.difference(atual.start).inDays;
    final isSelected = (diff - dias).abs() <= 1;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(dias),
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

Color _getCorStatus(StatusIndicador s) {
  switch (s) {
    case StatusIndicador.bom:
      return CoresApp.sucesso;
    case StatusIndicador.atencao:
      return CoresApp.atencao;
    case StatusIndicador.ruim:
      return CoresApp.erro;
    case StatusIndicador.neutro:
      return Colors.grey;
  }
}

// ============================================================================

