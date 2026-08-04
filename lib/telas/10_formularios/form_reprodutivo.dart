import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/animal.dart';
import '../../../modelos/eventos/evento_reprodutivo.dart';
import '../../../provedores/provedor_fazenda.dart';
import '../../../servicos/banco_dados_servico.dart';

class FormReprodutivo extends StatefulWidget {
  final Animal? animalPreSelecionado;

  const FormReprodutivo({super.key, this.animalPreSelecionado});

  @override
  State<FormReprodutivo> createState() => _FormReprodutivoState();
}

class _FormReprodutivoState extends State<FormReprodutivo> {
  final _formKey = GlobalKey<FormState>();
  final _resultadoController = TextEditingController();
  final _obsController = TextEditingController();
  final _dataController = TextEditingController();
  
  late DateTime _dataSelecionada;
  String? _animalIdSelecionado;
  String? _progenieIdSelecionado;
  String _tipoSelecionado = 'Inseminação (IA)';
  bool _salvando = false;
  bool _salvo = false;

  final List<String> _tipos = [
    'Inseminação (IA)',
    'Monta Natural',
    'Diagnóstico Gestação',
    'Parto',
    'Aborto',
    'Cio',
    'Desmame',
  ];

  @override
  void initState() {
    super.initState();
    _dataSelecionada = DateTime.now();
    _dataController.text = DateFormat('dd/MM/yyyy').format(_dataSelecionada);

    if (widget.animalPreSelecionado != null) {
      _animalIdSelecionado = widget.animalPreSelecionado!.id;
      // Machos só podem ter eventos de Desmame; ajusta o tipo para evitar
      // salvar um evento de fêmea (IA/Parto/Diagnóstico) em um macho.
      if (widget.animalPreSelecionado!.sexo != 'F' &&
          _tipoSelecionado != 'Desmame') {
        _tipoSelecionado = 'Desmame';
      }
    }
  }

  @override
  void dispose() {
    _resultadoController.dispose();
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

    if (_tipoSelecionado != 'Desmame') {
      final animal = context.read<ProvedorFazenda>().animais.firstWhere(
            (a) => a.id == _animalIdSelecionado,
            orElse: () => Animal(
              id: _animalIdSelecionado!,
              fazendaId: '',
              loteId: '',
              brinco: '?',
              raca: '',
              sexo: 'M',
              categoria: '',
              dataNascimento: DateTime.now(),
              pesoAtualKg: 0,
            ),
          );
      if (animal.sexo != 'F') {
        _mostrarErro('Este evento só pode ser registrado para fêmeas');
        return;
      }
    }

    setState(() => _salvando = true);

    try {
      final evento = EventoReprodutivo(
        animalId: _animalIdSelecionado!,
        data: _dataSelecionada,
        tipo: _tipoSelecionado,
        resultado: _resultadoController.text.isEmpty ? null : _resultadoController.text,
        observacao: _obsController.text.isEmpty ? null : _obsController.text,
        progenieId: _tipoSelecionado == 'Parto' ? _progenieIdSelecionado : null,
      );

      await BancoDadosServico.instancia.salvarEventoReprodutivo(evento);

      if (mounted) {
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva != null) {
          await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);
        }
        _mostrarSucesso('Evento reprodutivo registrado!');
        _salvo = true;
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
    final listaAnimais = _tipoSelecionado == 'Desmame'
        ? provedor.animais
        : provedor.animais.where((a) => a.sexo == 'F').toList();

    final formVazio = _resultadoController.text.isEmpty && _obsController.text.isEmpty
        && widget.animalPreSelecionado == null && _animalIdSelecionado == null
        && _progenieIdSelecionado == null;

    // Filhotes candidatos ao vínculo: bezerros/as ativos, que não sejam a mãe,
    // nascidos em uma janela ao redor da data do parto.
    final bezerrosCandidatos = _tipoSelecionado == 'Parto' &&
            _animalIdSelecionado != null
        ? provedor.animais.where((a) {
            final cat = a.categoria.toLowerCase();
            if (cat != 'bezerro' && cat != 'bezerra') return false;
            if (!a.isAtivo) return false;
            if (a.id == _animalIdSelecionado) return false;
            final diffDias = _dataSelecionada.difference(a.dataNascimento).inDays;
            return diffDias >= -60 && diffDias <= 60;
          }).toList()
        : <Animal>[];

    return PopScope(
      canPop: _salvo || formVazio,
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
      appBar: const AppBarPadrao(titulo: 'Manejo Reprodutivo', centralizar: true),
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
                      label: 'Data do Evento',
                      icone: Icons.calendar_today_outlined,
                      controller: _dataController,
                      soLeitura: true,
                      onTap: _selecionarData,
                    ),
                    const SizedBox(height: 16),
                    if (widget.animalPreSelecionado == null)
                      DropdownPadrao<String>(
                        label: _tipoSelecionado == 'Desmame' ? 'Animal' : 'Fêmea',
                        svgIcone: IconesApp.iconAnimalSvg,
                        valorSelecionado: _animalIdSelecionado,
                        itens: listaAnimais.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.brinco} - ${a.nome ?? "S/N"}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() {
                          _animalIdSelecionado = v;
                          _progenieIdSelecionado = null;
                        }),
                        validador: (v) => v == null ? 'Obrigatório' : null,
                      )
                    else
                      _WidgetInformativo(
                        svgIcone: IconesApp.iconAnimalSvg,
                        titulo: _tipoSelecionado == 'Desmame' ? 'Animal Selecionado' : 'Fêmea Selecionada',
                        valor: '${widget.animalPreSelecionado!.brinco} - ${widget.animalPreSelecionado!.nome ?? "Sem nome"}',
                      ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // --- CARD 2: DETALHES DO EVENTO ---
              const SecaoTitulo(texto: 'Dados Reprodutivos', icone: IconesApp.reproducao),
              CartaoPadrao(
                child: Column(
                  children: [
                    DropdownPadrao<String>(
                      label: 'Tipo de Evento',
                      icone: IconesApp.reproducao,
                      valorSelecionado: _tipoSelecionado,
                      itens: _tipos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        setState(() {
                          final novoTipo = v!;
                          final animal = _animalIdSelecionado != null
                              ? context.read<ProvedorFazenda>().animais.firstWhere(
                                  (a) => a.id == _animalIdSelecionado,
                                  orElse: () => Animal(
                                    id: _animalIdSelecionado!,
                                    fazendaId: '',
                                    loteId: '',
                                    brinco: '?',
                                    raca: '',
                                    sexo: 'M',
                                    categoria: '',
                                    dataNascimento: DateTime.now(),
                                    pesoAtualKg: 0,
                                  ),
                                )
                              : null;
                          if (novoTipo != 'Desmame' &&
                              animal != null &&
                              animal.sexo != 'F') {
                            if (widget.animalPreSelecionado != null) {
                              // Animal pré-selecionado é macho: mantém Desmame
                              // para não deixar o usuário em beco sem saída.
                              _mostrarErro(
                                'Machos só podem ter eventos de Desmame',
                              );
                              return;
                            }
                            _animalIdSelecionado = null;
                          }
                          _tipoSelecionado = novoTipo;
                          if (novoTipo != 'Parto') {
                            _progenieIdSelecionado = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_tipoSelecionado == 'Parto') ...[
                      DropdownPadrao<String>(
                        label: 'Bezerro nascido (opcional)',
                        icone: Icons.child_care_outlined,
                        valorSelecionado: _progenieIdSelecionado,
                        itens: bezerrosCandidatos.map((a) {
                          final nasc = DateFormat('dd/MM/yyyy').format(a.dataNascimento);
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.brinco} - ${a.nome ?? "S/N"} (nasc. $nasc)'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _progenieIdSelecionado = v),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CampoFormularioPadrao(
                      label: 'Resultado (Ex: Positivo, Confirmado)',
                      icone: Icons.info_outline_rounded,
                      controller: _resultadoController,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // --- CARD 3: OBSERVAÇÕES ---
              const SecaoTitulo(texto: 'Observações', icone: Icons.notes_rounded),
              CartaoPadrao(
                child: CampoFormularioPadrao(
                  label: 'Notas adicionais (Opcional)',
                  controller: _obsController,
                  maxLinhas: 3,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 40),

              // --- BOTÃO SALVAR ---
              BotaoPadrao(
                label: 'REGISTRAR EVENTO',
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
