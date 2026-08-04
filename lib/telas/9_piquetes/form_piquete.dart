import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../modelos/piquete.dart';
import '../../provedores/provedor_fazenda.dart';

class FormPiquete extends StatefulWidget {
  final Piquete? piqueteExistente;

  const FormPiquete({super.key, this.piqueteExistente});

  @override
  State<FormPiquete> createState() => _FormPiqueteState();
}

class _FormPiqueteState extends State<FormPiquete> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descController = TextEditingController();
  final _capacidadeController = TextEditingController();
  final _areaController = TextEditingController();

  String _tipoSelecionado = 'Pasto';
  String _sistemaProducao = 'Extensivo';
  bool _salvando = false;
  bool _salvo = false;

  final List<String> _tipos = [
    'Pasto', 'Confinamento', 'Maternidade', 'Curral', 'Outro'
  ];

  final List<String> _sistemas = ['Extensivo', 'Semi-Intensivo', 'Intensivo'];

  @override
  void initState() {
    super.initState();

    if (widget.piqueteExistente != null) {
      final p = widget.piqueteExistente!;
      _nomeController.text = p.nome;
      _descController.text = p.descricao;
      _capacidadeController.text = p.capacidade > 0 ? p.capacidade.toString() : '';
      _areaController.text = p.areaHectares > 0 ? p.areaHectares.toString() : '';
      if (_tipos.contains(p.tipo)) _tipoSelecionado = p.tipo;
      _sistemaProducao = p.sistemaProducao;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descController.dispose();
    _capacidadeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final provedor = context.read<ProvedorFazenda>();

    try {
      final novoPiquete = Piquete(
        id: widget.piqueteExistente?.id,
        fazendaId: provedor.propriedadeAtiva!.id,
        nome: _nomeController.text.trim(),
        descricao: _descController.text.trim(),
        tipo: _tipoSelecionado,
        capacidade: int.tryParse(_capacidadeController.text) ?? 0,
        sistemaProducao: _sistemaProducao,
        areaHectares: double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0.0,
      );

      if (widget.piqueteExistente != null) {
        await provedor.atualizarPiquete(novoPiquete);
      } else {
        await provedor.adicionarPiquete(novoPiquete);
      }
      _salvo = true;

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.piqueteExistente != null
                ? 'Piquete atualizado com sucesso!'
                : 'Piquete criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdicao = widget.piqueteExistente != null;

    final vazio = _nomeController.text.isEmpty && _descController.text.isEmpty && _capacidadeController.text.isEmpty && _areaController.text.isEmpty;

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
      appBar: AppBarPadrao(
        titulo: isEdicao ? 'Editar Piquete' : 'Novo Piquete',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SecaoTitulo(texto: 'Identificação', icone: IconesApp.piquete),
              CartaoPadrao(
                child: Column(
                  children: [
                    CampoFormularioPadrao(
                      label: 'Nome do Piquete / Pasto',
                      icone: IconesApp.piquete,
                      controller: _nomeController,
                      validador: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownPadrao<String>(
                      label: 'Tipo de Instalação',
                      icone: Icons.category_outlined,
                      valorSelecionado: _tipoSelecionado,
                      itens: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _tipoSelecionado = v!),
                    ),
                    const SizedBox(height: 16),
                    CampoFormularioPadrao(
                      label: 'Descrição (Opcional)',
                      icone: Icons.notes,
                      controller: _descController,
                      maxLinhas: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SecaoTitulo(texto: 'Capacidade e Área', icone: Icons.straighten_outlined),
              CartaoPadrao(
                child: Column(
                  children: [
                    CampoFormularioPadrao(
                      label: 'Capacidade (cabeças)',
                      icone: Icons.groups_outlined,
                      controller: _capacidadeController,
                      tipoTeclado: const TextInputType.numberWithOptions(decimal: false),
                    ),
                    const SizedBox(height: 16),
                    CampoFormularioPadrao(
                      label: 'Área (hectares)',
                      icone: Icons.terrain_outlined,
                      controller: _areaController,
                      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownPadrao<String>(
                      label: 'Sistema de Produção',
                      icone: Icons.agriculture_outlined,
                      valorSelecionado: _sistemaProducao,
                      itens: _sistemas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _sistemaProducao = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              BotaoPadrao(
                label: isEdicao ? 'SALVAR ALTERAÇÕES' : 'CRIAR PIQUETE',
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
