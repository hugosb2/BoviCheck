import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../modelos/propriedade.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/preferencias_usuario.dart';
import '../../servicos/banco_dados_servico.dart';
import '../4_dashboard/tela_dashboard.dart';

class FormDadosFazenda extends StatefulWidget {
  final Propriedade? propriedadeExistente;

  const FormDadosFazenda({super.key, this.propriedadeExistente});

  @override
  State<FormDadosFazenda> createState() => _FormDadosFazendaState();
}

class _FormDadosFazendaState extends State<FormDadosFazenda> {
  final PageController _pageController = PageController();

  final _nomeFazendaController = TextEditingController();
  final _proprietarioController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _areaController = TextEditingController();
  final _cepController = TextEditingController();

  String? _estadoSelecionado;
  String _sistemaProducao = 'Extensivo';
  bool _salvando = false;
  bool _buscandoCep = false;
  int _etapaAtual = 0;

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  final List<String> _sistemas = [
    'Extensivo', 'Semi-Confinamento', 'Confinamento', 'Leiteiro'
  ];

  @override
  void initState() {
    super.initState();

    if (widget.propriedadeExistente != null) {
      final p = widget.propriedadeExistente!;
      _nomeFazendaController.text = p.nomeFazenda;
      _proprietarioController.text = p.nomeProprietario;
      _cidadeController.text = p.cidade;
      _areaController.text = p.areaTotalHectares.toString().replaceAll('.', ',');
      _cepController.text = p.cep ?? '';
      _sistemaProducao = p.sistemaProducao;
      if (_estados.contains(p.estado)) _estadoSelecionado = p.estado;
    }
  }

  @override
  void dispose() {
    _nomeFazendaController.dispose();
    _proprietarioController.dispose();
    _cidadeController.dispose();
    _areaController.dispose();
    _cepController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _proximaEtapa() {
    if (_etapaAtual == 0) {
      if (_nomeFazendaController.text.isEmpty || _proprietarioController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha o nome da fazenda e proprietário'))
        );
        return;
      }
    }
    if (_etapaAtual == 1) {
      if (_cidadeController.text.isEmpty || _estadoSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha a cidade e estado'))
        );
        return;
      }
    }
    
    if (_etapaAtual < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _buscarCep(String cep) async {
    if (cep.length != 8) return;
    if (_buscandoCep) return;
    
    setState(() => _buscandoCep = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['erro'] != true && data['localidade'] != null) {
          setState(() {
            _cidadeController.text = data['localidade'] ?? '';
            _estadoSelecionado = data['uf'];
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('CEP: ${data['localidade']}/${data['uf']}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado'), backgroundColor: Colors.orange),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    if (_cidadeController.text.isEmpty || _estadoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a cidade e estado'))
      );
      return;
    }
    if (_areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a área total'))
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final original = widget.propriedadeExistente;
      final novaFazenda = Propriedade(
        id: original?.id ?? const Uuid().v4(),
        nomeFazenda: _nomeFazendaController.text.trim(),
        nomeProprietario: _proprietarioController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoSelecionado!,
        sistemaProducao: _sistemaProducao,
        areaTotalHectares: double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0.0,
        cep: _cepController.text.isEmpty ? original?.cep : _cepController.text.trim(),
        gpsLat: original?.gpsLat,
        gpsLong: original?.gpsLong,
        areaProducaoHectares: original?.areaProducaoHectares ?? 0.0,
        areaUtilizadaHectares: original?.areaUtilizadaHectares ?? 0.0,
      );

      if (widget.propriedadeExistente != null) {
        await BancoDadosServico.instancia.updatePropriedade(novaFazenda);
        if (!mounted) return;
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva?.id == novaFazenda.id) {
          await provedor.selecionarFazenda(novaFazenda.id);
        } else {
          await provedor.carregarPropriedades();
        }
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Dados atualizados!'), backgroundColor: Colors.green));
      } else {
        await context.read<ProvedorFazenda>().adicionarPropriedade(novaFazenda);
        await PreferenciasUsuario().salvarUltimaFazenda(novaFazenda.id);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TelaDashboard()),
          (route) => false,
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

  InputDecoration _inputDecor(String label, IconData icon, {String? suffix}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixText: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdicao = widget.propriedadeExistente != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarPadrao(
        titulo: isEdicao ? 'Editar Fazenda' : 'Nova Fazenda',
      ),
      body: Column(
        children: [
          _indicadorEtapas(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _etapaAtual = index),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _etapaIdentificacao(),
                _etapaLocalizacao(),
                _etapaSistema(),
              ],
            ),
          ),
          _botoesNavegacao(),
        ],
      ),
    );
  }

  Widget _indicadorEtapas() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          _circuloEtapa(0, 'Dados', Icons.badge_outlined),
          _linhaEtapa(0),
          _circuloEtapa(1, 'Local', Icons.location_on_outlined),
          _linhaEtapa(1),
          _circuloEtapa(2, 'Sistema', Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _circuloEtapa(int index, String label, IconData icone) {
    final theme = Theme.of(context);
    final isAtivo = _etapaAtual >= index;
    final isAtual = _etapaAtual == index;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isAtual 
                  ? Colors.white 
                  : (isAtivo ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icone,
              size: 18,
              color: isAtual ? theme.colorScheme.primary : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isAtual ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaEtapa(int index) {
    final isAtivo = _etapaAtual > index;
    
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isAtivo ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _etapaIdentificacao() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vamos começar!\nQual é o nome da sua fazenda?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informe os dados básicos da propriedade.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _nomeFazendaController,
            decoration: _inputDecor('Nome da Fazenda', IconesApp.fazenda),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _proprietarioController,
            decoration: _inputDecor('Nome do Proprietário', IconesApp.proprietario),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _etapaLocalizacao() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onde fica sua fazenda?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informe a localização para melhor gestão.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _cepController,
            decoration: _inputDecor('CEP', Icons.location_on_outlined).copyWith(
              suffixIcon: _buscandoCep
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _buscarCep(_cepController.text.replaceAll('-', '').replaceAll(' ', '')),
                    ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final cepNumerico = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (cepNumerico.length == 8) {
                _buscarCep(cepNumerico);
              }
              if (value.length == 5 && !value.contains('-')) {
                _cepController.text = '$value-';
                _cepController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _cepController.text.length),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _cidadeController,
                  decoration: _inputDecor('Cidade', IconesApp.localizacao),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _estadoSelecionado,
                  decoration: _inputDecor('UF', Icons.map),
                  isExpanded: true,
                  items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _estadoSelecionado = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _etapaSistema() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último passo!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete com informações do sistema de produção.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          DropdownButtonFormField<String>(
            initialValue: _sistemaProducao,
            decoration: _inputDecor('Sistema de Produção', Icons.settings_input_component),
            items: _sistemas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _sistemaProducao = v!),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _areaController,
            decoration: _inputDecor('Área Total', Icons.aspect_ratio, suffix: 'ha'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _botoesNavegacao() {
    final theme = Theme.of(context);
    final isEdicao = widget.propriedadeExistente != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _salvando 
                    ? null 
                    : (_etapaAtual < 2 ? _proximaEtapa : _salvar),
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_etapaAtual < 2 
                        ? 'PRÓXIMO' 
                        : (isEdicao ? 'SALVAR ALTERAÇÕES' : 'CRIAR FAZENDA')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
