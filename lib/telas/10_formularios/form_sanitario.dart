import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/animal.dart';
import '../../../modelos/eventos/evento_sanitario.dart';
import '../../../provedores/provedor_fazenda.dart';
import '../../../servicos/banco_dados_servico.dart';

class FormSanitario extends StatefulWidget {
  final Animal? animalPreSelecionado;

  const FormSanitario({super.key, this.animalPreSelecionado});

  @override
  State<FormSanitario> createState() => _FormSanitarioState();
}

class _FormSanitarioState extends State<FormSanitario> {
  final _formKey = GlobalKey<FormState>();
  final _medicamentoController = TextEditingController();
  final _doseController = TextEditingController();
  final _obsController = TextEditingController();
  final _dataController = TextEditingController();
  
  late DateTime _dataSelecionada;
  String? _animalIdSelecionado;
  String _tipoEvento = 'Vacinação';
  bool _salvando = false;
  bool _salvo = false;

  final List<String> _tipos = ['Vacinação', 'Doença', 'Tratamento', 'Vermifugação', 'Exame', 'Cirurgia', 'Outro'];

  @override
  void initState() {
    super.initState();
    _dataSelecionada = DateTime.now();
    _dataController.text = DateFormat('dd/MM/yyyy').format(_dataSelecionada);
    if (widget.animalPreSelecionado != null) _animalIdSelecionado = widget.animalPreSelecionado!.id;
  }

  @override
  void dispose() {
    _medicamentoController.dispose();
    _doseController.dispose();
    _obsController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_animalIdSelecionado == null) return _msg('Selecione um animal', erro: true);

    setState(() => _salvando = true);
    try {
      final evento = EventoSanitario(
        animalId: _animalIdSelecionado!,
        data: _dataSelecionada,
        tipo: _tipoEvento,
        nomeMedicamento: _medicamentoController.text.isEmpty ? null : _medicamentoController.text,
        dose: _doseController.text.isEmpty ? null : _doseController.text,
        observacao: _obsController.text.isEmpty ? null : _obsController.text,
      );

      await BancoDadosServico.instancia.salvarEventoSanitario(evento.toMap());
      if (mounted) {
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva != null) {
          await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);
        }
        _salvo = true;
        _msg('Evento sanitário registrado!');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _msg('Erro: $e', erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _msg(String txt, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt), backgroundColor: erro ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();

    final vazio = _medicamentoController.text.isEmpty && _doseController.text.isEmpty && _obsController.text.isEmpty && widget.animalPreSelecionado == null && _animalIdSelecionado == null;

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
      appBar: const AppBarPadrao(titulo: 'Manejo Sanitário', centralizar: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SecaoTitulo(texto: 'Data e Animal', icone: Icons.calendar_today),
              CartaoPadrao(
                child: Column(
                  children: [
                    CampoFormularioPadrao(
                      label: 'Data do Manejo',
                      icone: Icons.calendar_today_outlined,
                      controller: _dataController,
                      soLeitura: true,
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _dataSelecionada, firstDate: DateTime(2000), lastDate: DateTime.now());
                        if (d != null) setState(() { _dataSelecionada = d; _dataController.text = DateFormat('dd/MM/yyyy').format(d); });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (widget.animalPreSelecionado == null)
                      DropdownPadrao<String>(
                        label: 'Animal',
                        svgIcone: IconesApp.iconAnimalSvg,
                        valorSelecionado: _animalIdSelecionado,
                        itens: provedor.animais.where((a) => a.isAtivo).map((a) => DropdownMenuItem(value: a.id, child: Text('${a.brinco} - ${a.nome ?? "S/N"}'))).toList(),
                        onChanged: (v) => setState(() => _animalIdSelecionado = v),
                      )
                    else
                      _BoxInformativo(svgIcon: IconesApp.iconAnimalSvg, label: 'Animal', value: '${widget.animalPreSelecionado!.brinco} - ${widget.animalPreSelecionado!.nome ?? "S/N"}'),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),
              const SecaoTitulo(texto: 'Detalhes do Tratamento', icone: IconesApp.vacina),
              CartaoPadrao(
                child: Column(
                  children: [
                    DropdownPadrao<String>(
                      label: 'Tipo de Manejo',
                      icone: Icons.health_and_safety_outlined,
                      valorSelecionado: _tipoEvento,
                      itens: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _tipoEvento = v!),
                    ),
                    const SizedBox(height: 16),
                    CampoFormularioPadrao(label: 'Medicamento / Vacina', icone: Icons.medication_outlined, controller: _medicamentoController),
                    const SizedBox(height: 16),
                    CampoFormularioPadrao(label: 'Dosagem (Ex: 5ml, 2 comprimidos)', icone: Icons.straighten_outlined, controller: _doseController),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),
              const SecaoTitulo(texto: 'Notas', icone: Icons.notes_rounded),
              CartaoPadrao(
                child: CampoFormularioPadrao(label: 'Observações', controller: _obsController, maxLinhas: 3),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 40),
              BotaoPadrao(label: 'REGISTRAR MANEJO', icone: IconesApp.salvar, onPressed: _salvando ? null : _salvar, carregando: _salvando, expandido: true).animate().scale(delay: 300.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _BoxInformativo extends StatelessWidget {
  final String? svgIcon;
  final String label;
  final String value;
  const _BoxInformativo({this.svgIcon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          if (svgIcon != null)
            SvgPicture.asset(svgIcon!, width: 24, height: 24, colorFilter: ColorFilter.mode(theme.colorScheme.primary, BlendMode.srcIn)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
            Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}
