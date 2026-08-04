import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/animal.dart';
import '../../../modelos/eventos/producao_leite.dart';
import '../../../provedores/provedor_fazenda.dart';
import '../../../servicos/banco_dados_servico.dart';

class FormLeite extends StatefulWidget {
  final Animal? animalPreSelecionado;

  const FormLeite({super.key, this.animalPreSelecionado});

  @override
  State<FormLeite> createState() => _FormLeiteState();
}

class _FormLeiteState extends State<FormLeite> {
  final _formKey = GlobalKey<FormState>();
  final _litrosController = TextEditingController();
  final _obsController = TextEditingController();
  final _dataController = TextEditingController();

  late DateTime _dataSelecionada;
  String? _animalIdSelecionado;
  String _periodoSelecionado = 'Manhã';
  bool _salvando = false;
  bool _salvo = false;

  final List<String> _periodos = ['Manhã', 'Tarde', 'Noite'];

  @override
  void initState() {
    super.initState();
    _dataSelecionada = DateTime.now();
    _dataController.text = DateFormat('dd/MM/yyyy').format(_dataSelecionada);

    if (widget.animalPreSelecionado != null) {
      _animalIdSelecionado = widget.animalPreSelecionado!.id;
    }
  }

  @override
  void dispose() {
    _litrosController.dispose();
    _obsController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_animalIdSelecionado == null) {
      _mostrarErro('Selecione uma fêmea');
      return;
    }

    setState(() => _salvando = true);

    try {
      final litros = double.parse(_litrosController.text.replaceAll(',', '.'));

      final producao = ProducaoLeite(
        animalId: _animalIdSelecionado!,
        data: _dataSelecionada,
        litros: litros,
        periodo: _periodoSelecionado,
        observacao: _obsController.text.isEmpty ? null : _obsController.text,
      );

      await BancoDadosServico.instancia.salvarProducaoLeite(producao);

      if (mounted) {
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva != null) {
          await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);
        }
        _salvo = true;
        _mostrarSucesso('Produção de leite salva com sucesso!');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _mostrarErro('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
    );
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade800, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final femeas = provedor.animais
        .where((a) => a.sexo == 'F' && a.isAtivo)
        .where((a) {
      final cat = a.categoria.toLowerCase();
      return cat != 'bezerra' && cat != 'novilha';
    }).toList();

    final vazio = _litrosController.text.isEmpty && _obsController.text.isEmpty && widget.animalPreSelecionado == null && _animalIdSelecionado == null;

    return PopScope(
      canPop: _salvo || vazio,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Descartar dados?'),
              content: const Text('Há informações não salvas. Deseja realmente sair?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CONTINUAR')),
                TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('SAIR')),
              ],
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Produção de Leite', centralizar: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CARD 1: DATA E ANIMAL ---
              const SecaoTitulo(texto: 'Identificação', icone: Icons.calendar_today_outlined),
              CartaoPadrao(
                child: Column(
                  children: [
                    CampoFormularioPadrao(
                      label: 'Data da Ordenha',
                      icone: Icons.calendar_today_outlined,
                      controller: _dataController,
                      soLeitura: true,
                      onTap: _selecionarData,
                    ),
                    const SizedBox(height: 16),
                    if (widget.animalPreSelecionado == null)
                      DropdownPadrao<String>(
                        label: 'Vaca',
                        svgIcone: IconesApp.iconAnimalSvg,
                        valorSelecionado: _animalIdSelecionado,
                        itens: femeas.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.brinco} - ${a.nome ?? "S/N"}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _animalIdSelecionado = v),
                        validador: (v) => v == null ? 'Obrigatório' : null,
                      )
                    else
                      _WidgetInformativo(
                        svgIcone: IconesApp.iconAnimalSvg,
                        titulo: 'Vaca Selecionada',
                        valor: '${widget.animalPreSelecionado!.brinco} - ${widget.animalPreSelecionado!.nome ?? "Sem nome"}',
                      ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // --- CARD 2: DADOS DA PRODUÇÃO ---
              const SecaoTitulo(texto: 'Dados da Produção', icone: IconesApp.leite),
              CartaoPadrao(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CampoFormularioPadrao(
                            label: 'Quantidade',
                            icone: IconesApp.leite,
                            controller: _litrosController,
                            tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                            validador: (v) {
                              if (v!.isEmpty) return 'Obrigatório';
                              if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('Litros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownPadrao<String>(
                      label: 'Período',
                      icone: Icons.schedule_rounded,
                      valorSelecionado: _periodoSelecionado,
                      itens: _periodos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _periodoSelecionado = v!),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // --- CARD 3: OBSERVAÇÕES ---
              const SecaoTitulo(texto: 'Observações', icone: Icons.notes_rounded),
              CartaoPadrao(
                child: CampoFormularioPadrao(
                  label: 'Detalhes da ordenha (Opcional)',
                  controller: _obsController,
                  maxLinhas: 3,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 40),

              // --- BOTÃO SALVAR ---
              BotaoPadrao(
                label: 'SALVAR PRODUÇÃO',
                icone: IconesApp.salvar,
                onPressed: _salvando ? null : _salvar,
                carregando: _salvando,
                expandido: true,
              ).animate().scale(delay: 300.ms),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _WidgetInformativo extends StatelessWidget {
  final String? svgIcone;
  final String titulo;
  final String valor;

  const _WidgetInformativo({this.svgIcone, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          if (svgIcone != null)
            SvgPicture.asset(svgIcone!, width: 24, height: 24, colorFilter: ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                Text(valor, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
