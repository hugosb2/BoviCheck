import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../modelos/animal.dart';
import '../../modelos/piquete.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/banco_dados_servico.dart';
import '../10_formularios/form_pesagem.dart';
import '../10_formularios/form_reprodutivo.dart';
import '../10_formularios/form_leite.dart';
import '../10_formularios/form_sanitario.dart';
import '../10_formularios/form_abate.dart';
import 'form_animal.dart';

class TelaDetalhesAnimal extends StatefulWidget {
  final Animal animal;

  const TelaDetalhesAnimal({super.key, required this.animal});

  @override
  State<TelaDetalhesAnimal> createState() => _TelaDetalhesAnimalState();
}

class _TelaDetalhesAnimalState extends State<TelaDetalhesAnimal> {
  List<Map<String, dynamic>> _historico = [];
  bool _carregandoHistorico = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final animalId = widget.animal.id;
    final db = BancoDadosServico.instancia;
    
    final pesagens = await db.getPesagensPorAnimal(animalId);
    final reprodutivos = await db.getEventosReprodutivosPorAnimal(animalId);
    final leite = await db.getProducaoLeitePorAnimal(animalId);
    final sanitarios = await db.getEventosSanitariosPorAnimal(animalId);
    final abates = await db.getAbatesPorAnimal(animalId);

    List<Map<String, dynamic>> temp = [];

    for (var p in pesagens) {
      temp.add({'tipo': 'Pesagem', 'data': p.data, 'desc': '${p.pesoKg} kg'});
    }
    for (var r in reprodutivos) {
      temp.add({'tipo': 'Reprodutivo', 'data': r.data, 'desc': '${r.tipo} ${r.resultado != null ? '(${r.resultado})' : ''}'});
    }
    for (var l in leite) {
      temp.add({'tipo': 'Leite', 'data': l.data, 'desc': '${l.litros} L - ${l.periodo}'});
    }
    for (var s in sanitarios) {
      temp.add({'tipo': 'Sanitário', 'data': DateTime.parse(s['data'].toString()), 'desc': '${s['tipo']} ${s['nomeMedicamento'] ?? ''}'});
    }
    for (var a in abates) {
      temp.add({'tipo': 'Abate', 'data': DateTime.parse(a['data'].toString()), 'desc': '${a['pesoCarcacaKg']} kg carcaça'});
    }

    temp.sort((a, b) => (b['data'] as DateTime).compareTo(a['data'] as DateTime));

    if (mounted) {
      setState(() {
        _historico = temp;
        _carregandoHistorico = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final animalAtual = provedor.animais
        .firstWhere((a) => a.id == widget.animal.id, orElse: () => widget.animal);
    final Piquete? piquete = provedor.piquetes.isEmpty
        ? null
        : provedor.piquetes.cast<Piquete?>().firstWhere(
            (p) => p?.id == animalAtual.loteId,
            orElse: () => null,
          );
    final bool inativo = !animalAtual.isAtivo;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarPadrao(
        titulo: animalAtual.nome ?? 'Animal #${animalAtual.brinco}',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormAnimal(animalExistente: animalAtual)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _heroAnimal(theme, animalAtual, piquete, inativo).animate().fadeIn(duration: 300.ms),

          if (inativo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _avisoInativo(theme),
            ).animate().fadeIn(),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _gridFicha(theme, animalAtual, piquete),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          _blocoPeso(theme, animalAtual).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _blocoAcoes(context, theme, animalAtual),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),

          _blocoRegistros(context, theme).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormAnimal(animalExistente: animalAtual))),
        icon: const Icon(Icons.edit),
        label: const Text('EDITAR'),
      ),
    );
  }

  // ---- HEADER HERO ----

  Widget _heroAnimal(ThemeData theme, Animal animal, Piquete? piquete, bool inativo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            inativo ? Colors.grey.shade700 : theme.colorScheme.primary,
            inativo ? Colors.grey.shade500 : theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: (inativo ? Colors.grey : theme.colorScheme.primary).withValues(alpha: 0.3),
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
                        animal.nome ?? 'Animal #${animal.brinco}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Brinco ${animal.brinco}',
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
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.asset(
                      IconesApp.iconAnimalSvg,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _heroBadge(animal.sexo == 'M' ? 'Macho' : 'Fêmea', Colors.white, theme, animal.sexo == 'M' ? Colors.blue : Colors.pink),
                const SizedBox(width: 8),
                _heroBadge(animal.categoria, Colors.white, theme, Colors.amber.shade400),
                const SizedBox(width: 8),
                if (piquete != null)
                  _heroBadge(piquete.nome, Colors.white, theme, Colors.green.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge(String texto, Color corTexto, ThemeData theme, Color corFundo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: corFundo.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: corFundo.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: corTexto,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  // ---- AVISO INATIVO ----

  Widget _avisoInativo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este animal está inativo/morto.',
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ---- GRID FICHA TÉCNICA ----

  Widget _gridFicha(ThemeData theme, Animal animal, Piquete? piquete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SecaoLabel(texto: 'Ficha Técnica'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _fichaItem(theme, IconesApp.piquete, 'Piquete', piquete?.nome ?? '—', cor: Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _fichaItem(theme, IconesApp.iconAnimalSvg, 'Raça', animal.raca)),
            const SizedBox(width: 12),
            Expanded(child: _fichaItem(theme, Icons.cake_outlined, 'Idade', '${animal.calcularIdadeMeses()} meses', cor: Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _fichaItem(ThemeData theme, dynamic icone, String rotulo, String valor, {Color? cor}) {
    cor ??= theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          icone is IconData
              ? Icon(icone, color: cor, size: 24)
              : SvgPicture.asset(
                  icone as String,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
                ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---- BLOCO PESO ----

  Widget _blocoPeso(ThemeData theme, Animal animal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoLabel(texto: 'Peso Atual'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconesApp.peso, size: 40, color: theme.colorScheme.primary),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          animal.pesoAtualKg.toStringAsFixed(1),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'kg',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Nascimento: ${DateFormat('dd/MM/yyyy').format(animal.dataNascimento)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${animal.id.length > 8 ? '${animal.id.substring(0, 8)}...' : animal.id}',
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- BLOCO AÇÕES RÁPIDAS ----

  Widget _blocoAcoes(BuildContext context, ThemeData theme, Animal animal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SecaoLabel(texto: 'Ações Rápidas'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _acaoItem(context, theme, IconesApp.peso, 'Pesagem', Colors.indigo, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => FormPesagem(animalPreSelecionado: animal)));
              _carregarHistorico();
            })),
            const SizedBox(width: 12),
            Expanded(child: _acaoItem(context, theme, Icons.favorite, 'Reprodutivo', Colors.pink, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => FormReprodutivo(animalPreSelecionado: animal)));
              _carregarHistorico();
            })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (animal.sexo == 'F' &&
                animal.isAtivo &&
                animal.categoria != 'Bezerra' &&
                animal.categoria != 'Novilha')
              Expanded(child: _acaoItem(context, theme, Icons.water_drop, 'Leite', Colors.cyan, () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => FormLeite(animalPreSelecionado: animal)));
                _carregarHistorico();
              }))
            else
              const Expanded(child: SizedBox.shrink()),
            const SizedBox(width: 12),
            Expanded(child: _acaoItem(context, theme, Icons.medical_services, 'Sanitário', Colors.red, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => FormSanitario(animalPreSelecionado: animal)));
              _carregarHistorico();
            })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (animal.isAtivo && animal.status == 'Ativo')
              Expanded(child: _acaoItem(context, theme, Icons.restaurant, 'Abate', Colors.brown, () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => FormAbate(animalPreSelecionado: animal)));
                _carregarHistorico();
              }))
            else
              const Expanded(child: SizedBox.shrink()),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _acaoItem(BuildContext context, ThemeData theme, IconData icone, String label, Color cor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  // ---- BLOCO REGISTROS ----

  Widget _blocoRegistros(BuildContext context, ThemeData theme) {
    final categorias = [
      const _CatReg('Pesagens', IconesApp.peso, 'Pesagem', Colors.indigo),
      const _CatReg('Reprodutivo', Icons.favorite, 'Reprodutivo', Colors.pink),
      const _CatReg('Produção de Leite', Icons.water_drop, 'Leite', Colors.cyan),
      const _CatReg('Sanitário', Icons.medical_services, 'Sanitário', Colors.red),
      const _CatReg('Abates', Icons.restaurant, 'Abate', Colors.brown),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoLabel(texto: 'Registros por Categoria'),
          const SizedBox(height: 14),
          if (_carregandoHistorico)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_historico.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Nenhum registro encontrado',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...categorias.map((cat) => _cardCategoria(theme, cat)),
        ],
      ),
    );
  }

  Widget _cardCategoria(ThemeData theme, _CatReg cat) {
    final eventos = _historico.where((e) => e['tipo'] == cat.tipo).toList();
    if (eventos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cat.cor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cat.cor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icone, color: cat.cor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cat.titulo,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.cor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${eventos.length}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: cat.cor),
                    ),
                  ),
                ],
              ),
            ),
            ...eventos.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e['desc'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    ),
                    Text(
                      DateFormat('dd/MM').format(e['data'] as DateTime),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 6),
          ],
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
        Container(width: 4, height: 20, decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 10),
        Text(
          texto,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _CatReg {
  final String titulo;
  final IconData icone;
  final String tipo;
  final Color cor;
  const _CatReg(this.titulo, this.icone, this.tipo, this.cor);
}
