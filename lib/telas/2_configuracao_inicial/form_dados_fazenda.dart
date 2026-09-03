import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../estilos/tema.dart';
import '../../modelos/propriedade.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/preferencias_usuario.dart';
import '../../servicos/banco_dados_servico.dart';
import '../4_dashboard/tela_dashboard.dart';
import 'widgets/indicador_etapas.dart';
import 'widgets/etapa_identificacao.dart';
import 'widgets/etapa_localizacao.dart';
import 'widgets/etapa_sistema.dart';

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
  final List<String> _estados = ['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];
  final List<String> _sistemas = ['Extensivo','Semi-Confinamento','Confinamento','Leiteiro'];

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
    _nomeFazendaController.dispose(); _proprietarioController.dispose(); _cidadeController.dispose(); _areaController.dispose(); _cepController.dispose(); _pageController.dispose();
    super.dispose();
  }

  void _proximaEtapa() {
    if (_etapaAtual == 0 && (_nomeFazendaController.text.isEmpty || _proprietarioController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome da fazenda e proprietário')));
      return;
    }
    if (_etapaAtual == 1 && (_cidadeController.text.isEmpty || _estadoSelecionado == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha a cidade e estado')));
      return;
    }
    if (_etapaAtual < 2) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _buscarCep(String cep) async {
    if (cep.length != 8 || _buscandoCep) return;
    setState(() => _buscandoCep = true);
    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] != true && data['localidade'] != null) {
          setState(() {_cidadeController.text = data['localidade'] ?? ''; _estadoSelecionado = data['uf'];});
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CEP: ${data['localidade']}/${data['uf']}'), backgroundColor: Colors.green));
        } else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP não encontrado'), backgroundColor: Colors.orange));
      } else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível consultar o CEP. Verifique sua conexão e preencha cidade/UF manualmente.'), backgroundColor: Colors.orange));
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem conexão para consultar o CEP. Preencha a cidade e UF manualmente.'), backgroundColor: Colors.orange));
    } finally { if (mounted) setState(() => _buscandoCep = false); }
  }

  Future<void> _salvar() async {
    if (_cidadeController.text.isEmpty || _estadoSelecionado == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha a cidade e estado'))); return; }
    if (_areaController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha a área total'))); return; }
    setState(() => _salvando = true);
    try {
      final original = widget.propriedadeExistente;
      final novaFazenda = Propriedade(id: original?.id ?? const Uuid().v4(), nomeFazenda: _nomeFazendaController.text.trim(), nomeProprietario: _proprietarioController.text.trim(), cidade: _cidadeController.text.trim(), estado: _estadoSelecionado!, sistemaProducao: _sistemaProducao, areaTotalHectares: double.tryParse(_areaController.text.replaceAll(',', '.')) ?? 0.0, cep: _cepController.text.isEmpty ? original?.cep : _cepController.text.trim(), gpsLat: original?.gpsLat, gpsLong: original?.gpsLong, areaProducaoHectares: original?.areaProducaoHectares ?? 0.0, areaUtilizadaHectares: original?.areaUtilizadaHectares ?? 0.0);
      if (widget.propriedadeExistente != null) {
        await BancoDadosServico.instancia.updatePropriedade(novaFazenda);
        if (!mounted) return;
        final provedor = context.read<ProvedorFazenda>();
        if (provedor.propriedadeAtiva?.id == novaFazenda.id) await provedor.selecionarFazenda(novaFazenda.id); else await provedor.carregarPropriedades();
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados!'), backgroundColor: Colors.green));
      } else {
        await context.read<ProvedorFazenda>().adicionarPropriedade(novaFazenda);
        await PreferenciasUsuario().salvarUltimaFazenda(novaFazenda.id);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const TelaDashboard()), (route) => false);
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red)); } finally { if (mounted) setState(() => _salvando = false); }
  }

  InputDecoration _inputDecor(String label, IconData icon, {String? suffix}) {
    final theme = Theme.of(context);
    return InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixText: suffix, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.outlineVariant)), filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdicao = widget.propriedadeExistente != null;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarPadrao(titulo: isEdicao ? 'Editar Fazenda' : 'Nova Fazenda'),
      body: Column(children: [
        IndicadorEtapas(etapaAtual: _etapaAtual),
        Expanded(child: PageView(controller: _pageController, onPageChanged: (index) => setState(() => _etapaAtual = index), physics: const NeverScrollableScrollPhysics(), children: [
          EtapaIdentificacao(nomeFazendaController: _nomeFazendaController, proprietarioController: _proprietarioController, inputDecor: _inputDecor),
          EtapaLocalizacao(cepController: _cepController, cidadeController: _cidadeController, estadoSelecionado: _estadoSelecionado, estados: _estados, buscandoCep: _buscandoCep, onBuscarCep: _buscarCep, onEstadoChanged: (v) => setState(() => _estadoSelecionado = v), inputDecor: _inputDecor),
          EtapaSistema(sistemaProducao: _sistemaProducao, sistemas: _sistemas, areaController: _areaController, onSistemaChanged: (v) => setState(() => _sistemaProducao = v!), inputDecor: _inputDecor),
        ])),
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))]), child: SafeArea(child: Row(children: [Expanded(child: FilledButton(onPressed: _salvando ? null : (_etapaAtual < 2 ? _proximaEtapa : _salvar), child: _salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_etapaAtual < 2 ? 'PRÓXIMO' : (isEdicao ? 'SALVAR ALTERAÇÕES' : 'CRIAR FAZENDA'))))]))),
      ]),
    );
  }
}
