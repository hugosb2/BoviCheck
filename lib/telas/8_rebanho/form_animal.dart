import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/animal.dart';
import '../../../provedores/provedor_fazenda.dart';
import '../../../servicos/banco_dados_servico.dart';
import 'widgets/barra_progresso_moderno.dart';
import 'widgets/botoes_navegacao.dart';
import 'widgets/pagina_identificacao.dart';
import 'widgets/pagina_caracteristicas.dart';
import 'widgets/pagina_revisao.dart';

class FormAnimal extends StatefulWidget {
  final Animal? animalExistente;
  const FormAnimal({super.key, this.animalExistente});
  @override
  State<FormAnimal> createState() => _FormAnimalState();
}

class _FormAnimalState extends State<FormAnimal> {
  final _pageController = PageController();
  int _etapaAtual = 0;
  final int _totalEtapas = 3;

  final _brincoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _pesoController = TextEditingController();

  String? _piqueteSelecionadoId;
  String _sexo = 'M';
  String _categoria = 'Bezerro';
  DateTime _dataNascimento = DateTime.now();
  bool _salvando = false;
  bool _salvo = false;

  String _status = 'Ativo';
  DateTime? _dataObito;
  final _causaObitoController = TextEditingController();
  DateTime? _dataSaida;
  final _motivoSaidaController = TextEditingController();

  final List<String> _categorias = ['Bezerro', 'Bezerra', 'Novilho', 'Novilha', 'Boi', 'Vaca', 'Touro', 'Outro'];

  @override
  void initState() {
    super.initState();
    if (widget.animalExistente != null) {
      final a = widget.animalExistente!;
      _brincoController.text = a.brinco;
      _nomeController.text = a.nome ?? '';
      _racaController.text = a.raca;
      _pesoController.text = a.pesoAtualKg.toString();
      _piqueteSelecionadoId = a.loteId;
      _sexo = a.sexo;
      _categoria = a.categoria;
      _dataNascimento = a.dataNascimento;
      _status = a.status;
      _dataObito = a.dataObito;
      _causaObitoController.text = a.causaObito ?? '';
      _dataSaida = a.dataSaida;
      _motivoSaidaController.text = a.motivoSaida ?? '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _brincoController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _pesoController.dispose();
    _causaObitoController.dispose();
    _motivoSaidaController.dispose();
    super.dispose();
  }

  void _irParaEtapa(int etapa) {
    setState(() => _etapaAtual = etapa);
    _pageController.animateToPage(etapa, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
  }

  bool _validarEtapa(int etapa) {
    if (etapa == 0) {
      if (_brincoController.text.isEmpty) return _erro('Informe o número do brinco');
      if (_piqueteSelecionadoId == null) return _erro('Selecione um piquete ou pasto');
    }
    if (etapa == 1) {
      if (_racaController.text.isEmpty) return _erro('Informe a raça do animal');
    }
    return true;
  }

  bool _erro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating));
    return false;
  }

  void _proximaEtapa() {
    if (!_validarEtapa(_etapaAtual)) return;
    if (_etapaAtual < _totalEtapas - 1) {
      _irParaEtapa(_etapaAtual + 1);
    } else {
      _salvar();
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final provedor = context.read<ProvedorFazenda>();
    try {
      if (_status == 'Morto' && _dataObito == null) {
        _erro('Informe a data do óbito para o status Morto');
        return;
      }
      if (_status == 'Vendido' && _dataSaida == null) {
        _erro('Informe a data da saída para o status Vendido');
        return;
      }
      final ehAtivo = _status == 'Ativo';
      final novoAnimal = Animal(
        id: widget.animalExistente?.id,
        fazendaId: provedor.propriedadeAtiva!.id,
        loteId: _piqueteSelecionadoId!,
        brinco: _brincoController.text,
        nome: _nomeController.text.isEmpty ? null : _nomeController.text,
        raca: _racaController.text,
        sexo: _sexo,
        categoria: _categoria,
        dataNascimento: _dataNascimento,
        pesoAtualKg: double.tryParse(_pesoController.text.replaceAll(',', '.')) ?? 0.0,
        isAtivo: ehAtivo,
        status: _status,
        dataObito: _status == 'Morto' ? _dataObito : null,
        causaObito: _status == 'Morto' ? (_causaObitoController.text.isEmpty ? null : _causaObitoController.text) : null,
        dataSaida: _status == 'Vendido' ? _dataSaida : null,
        motivoSaida: _status == 'Vendido' ? (_motivoSaidaController.text.isEmpty ? null : _motivoSaidaController.text) : null,
      );
      final db = BancoDadosServico.instancia;
      if (widget.animalExistente != null) {
        await db.updateAnimal(novoAnimal);
      } else {
        await db.adicionarAnimal(novoAnimal);
      }
      await provedor.carregarAnimais(provedor.propriedadeAtiva!.id);
      _salvo = true;
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sucesso!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) _erro('Erro: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdicao = widget.animalExistente != null;
    final camposPreenchidos = _brincoController.text.isNotEmpty || _nomeController.text.isNotEmpty || _racaController.text.isNotEmpty || _pesoController.text.isNotEmpty || _piqueteSelecionadoId != null;

    return PopScope(
      canPop: _salvo || !camposPreenchidos,
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
        appBar: AppBarPadrao(titulo: isEdicao ? 'Editar Animal' : 'Novo Animal', centralizar: true),
        body: Column(
          children: [
            BarraProgressoModerno(etapaAtual: _etapaAtual, total: _totalEtapas),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  PaginaIdentificacao(
                    brincoController: _brincoController,
                    nomeController: _nomeController,
                    piqueteSelecionadoId: _piqueteSelecionadoId,
                    onPiqueteChanged: (v) => setState(() => _piqueteSelecionadoId = v),
                  ),
                  PaginaCaracteristicas(
                    racaController: _racaController,
                    sexo: _sexo,
                    categoria: _categoria,
                    categorias: _categorias,
                    dataNascimento: _dataNascimento,
                    onSexoChanged: (v) => setState(() => _sexo = v),
                    onCategoriaChanged: (v) => setState(() => _categoria = v),
                    onDataTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _dataNascimento, firstDate: DateTime(2000), lastDate: DateTime.now());
                      if (d != null) setState(() => _dataNascimento = d);
                    },
                  ),
                  PaginaRevisao(
                    pesoController: _pesoController,
                    brinco: _brincoController.text,
                    raca: _racaController.text,
                    loteId: _piqueteSelecionadoId,
                    status: _status,
                    dataObito: _dataObito,
                    causaObitoController: _causaObitoController,
                    dataSaida: _dataSaida,
                    motivoSaidaController: _motivoSaidaController,
                    onStatusChanged: (v) => setState(() => _status = v),
                    onDataObitoTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _dataObito ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                      if (d != null) setState(() => _dataObito = d);
                    },
                    onDataSaidaTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _dataSaida ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                      if (d != null) setState(() => _dataSaida = d);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BotoesNavegacao(
          etapaAtual: _etapaAtual,
          total: _totalEtapas,
          salvando: _salvando,
          onProximo: _proximaEtapa,
        ),
      ),
    );
  }
}
