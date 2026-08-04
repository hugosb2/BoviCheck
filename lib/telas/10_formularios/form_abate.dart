import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../modelos/animal.dart';
import '../../modelos/eventos/abate.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/banco_dados_servico.dart';

class FormAbate extends StatefulWidget {
  final Animal? animalPreSelecionado;

  const FormAbate({super.key, this.animalPreSelecionado});

  @override
  State<FormAbate> createState() => _FormAbateState();
}

class _FormAbateState extends State<FormAbate> {
  final _formKey = GlobalKey<FormState>();
  final _pesoVivoController = TextEditingController();
  final _pesoCarcacaController = TextEditingController();
  final _observacaoController = TextEditingController();

  late DateTime _dataAbate;
  String? _animalIdSelecionado;
  bool _salvando = false;
  bool _salvo = false;

  @override
  void initState() {
    super.initState();
    _dataAbate = DateTime.now();
    if (widget.animalPreSelecionado != null) {
      _animalIdSelecionado = widget.animalPreSelecionado!.id;
      _pesoVivoController.text = widget.animalPreSelecionado!.pesoAtualKg.toString();
    }
  }

  @override
  void dispose() {
    _pesoVivoController.dispose();
    _pesoCarcacaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  String get _dataFormatada => DateFormat('dd/MM/yyyy').format(_dataAbate);

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataAbate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dataAbate = picked);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_animalIdSelecionado == null) {
      _mostrarErro('Selecione um animal');
      return;
    }

    setState(() => _salvando = true);

    try {
      final abate = Abate(
        id: const Uuid().v4(),
        animalId: _animalIdSelecionado!,
        data: _dataAbate,
        pesoVivoKg: double.parse(_pesoVivoController.text.replaceAll(',', '.')),
        pesoCarcacaKg: double.parse(_pesoCarcacaController.text.replaceAll(',', '.')),
        observacao: _observacaoController.text.isEmpty ? null : _observacaoController.text,
      );

      final db = BancoDadosServico.instancia;
      await db.salvarAbate(abate.toMap());

      if (!mounted) return;
      final provedor = context.read<ProvedorFazenda>();

      final animal = provedor.animais.firstWhere(
        (a) => a.id == _animalIdSelecionado,
        orElse: () => Animal(
          id: _animalIdSelecionado!,
          fazendaId: provedor.propriedadeAtiva?.id ?? '',
          loteId: '',
          brinco: '?',
          raca: '',
          sexo: 'M',
          categoria: 'Indefinido',
          dataNascimento: _dataAbate,
          pesoAtualKg: double.tryParse(_pesoVivoController.text.replaceAll(',', '.')) ?? 0.0,
        ),
      );

      final animalAbatido = Animal(
        id: animal.id,
        fazendaId: animal.fazendaId,
        loteId: animal.loteId,
        brinco: animal.brinco,
        nome: animal.nome,
        raca: animal.raca,
        sexo: animal.sexo,
        categoria: animal.categoria,
        dataNascimento: animal.dataNascimento,
        pesoAtualKg: animal.pesoAtualKg,
        isAtivo: false,
        status: 'Vendido',
        dataSaida: _dataAbate,
        motivoSaida: 'Abate',
        paiId: animal.paiId,
        maeId: animal.maeId,
      );
      await db.updateAnimal(animalAbatido);

      await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);

      if (!mounted) return;
      _salvo = true;
      _mostrarSucesso('Abate registrado com sucesso!');
      Navigator.pop(context);
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

    final vazio = _pesoVivoController.text.isEmpty && _pesoCarcacaController.text.isEmpty && _observacaoController.text.isEmpty && widget.animalPreSelecionado == null && _animalIdSelecionado == null;

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
      appBar: const AppBarPadrao(titulo: 'Registrar Abate', centralizar: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SecaoTitulo(texto: 'Animal', svgIcone: IconesApp.iconAnimalSvg),
              CartaoPadrao(
                child: Column(
                  children: [
                    if (widget.animalPreSelecionado == null)
                      DropdownPadrao<String>(
                        label: 'Selecione o animal',
                        svgIcone: IconesApp.iconAnimalSvg,
                        valorSelecionado: _animalIdSelecionado,
                        itens: provedor.animais.where((a) => a.isAtivo).map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.brinco} - ${a.nome ?? a.raca}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _animalIdSelecionado = val;
                            if (val != null) {
                              final animal = provedor.animais.firstWhere((a) => a.id == val);
                              _pesoVivoController.text = animal.pesoAtualKg.toString();
                            }
                          });
                        },
                        validador: (v) => v == null ? 'Obrigatório' : null,
                      )
                    else
                      _WidgetInformativo(
                        svgIcone: IconesApp.iconAnimalSvg,
                        titulo: 'Animal Selecionado',
                        valor: '${widget.animalPreSelecionado!.brinco} - ${widget.animalPreSelecionado!.nome ?? "Sem nome"}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SecaoTitulo(texto: 'Dados do Abate', icone: Icons.fitness_center),
              CartaoPadrao(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _selecionarData,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data do Abate',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(_dataFormatada, style: theme.textTheme.bodyLarge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CampoFormularioPadrao(
                            label: 'Peso Vivo (kg)',
                            icone: IconesApp.peso,
                            controller: _pesoVivoController,
                            tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                            validador: (v) {
                              if (v!.isEmpty) return 'Obrigatório';
                              if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CampoFormularioPadrao(
                            label: 'Carcaça (kg)',
                            icone: Icons.fitness_center,
                            controller: _pesoCarcacaController,
                            tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                            validador: (v) {
                              if (v!.isEmpty) return 'Obrigatório';
                              if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SecaoTitulo(texto: 'Observações', icone: Icons.notes_rounded),
              CartaoPadrao(
                child: CampoFormularioPadrao(
                  label: 'Informações adicionais (Opcional)',
                  controller: _observacaoController,
                  maxLinhas: 3,
                ),
              ),
              const SizedBox(height: 40),
              BotaoPadrao(
                label: 'REGISTRAR ABATE',
                icone: IconesApp.salvar,
                onPressed: _salvando ? null : _salvar,
                carregando: _salvando,
                expandido: true,
              ),
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
