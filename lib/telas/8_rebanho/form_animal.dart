import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/animal.dart';
import '../../../modelos/piquete.dart';
import '../../../provedores/provedor_fazenda.dart';
import '../../../servicos/banco_dados_servico.dart';

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

  final List<String> _categorias = [
    'Bezerro', 'Bezerra', 'Novilho', 'Novilha', 'Boi', 'Vaca', 'Touro', 'Outro',
  ];

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
        causaObito: _status == 'Morto'
            ? (_causaObitoController.text.isEmpty ? null : _causaObitoController.text)
            : null,
        dataSaida: _status == 'Vendido' ? _dataSaida : null,
        motivoSaida: _status == 'Vendido'
            ? (_motivoSaidaController.text.isEmpty ? null : _motivoSaidaController.text)
            : null,
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

    final camposPreenchidos = _brincoController.text.isNotEmpty ||
        _nomeController.text.isNotEmpty ||
        _racaController.text.isNotEmpty ||
        _pesoController.text.isNotEmpty ||
        _piqueteSelecionadoId != null;

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
          _BarraProgressoModerno(etapaAtual: _etapaAtual, total: _totalEtapas),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PaginaIdentificacao(
                  brincoController: _brincoController,
                  nomeController: _nomeController,
                  piqueteSelecionadoId: _piqueteSelecionadoId,
                  onPiqueteChanged: (v) => setState(() => _piqueteSelecionadoId = v),
                ),
                _PaginaCaracteristicas(
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
                _PaginaRevisao(
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
      bottomNavigationBar: _BotoesNavegacao(
        etapaAtual: _etapaAtual,
        total: _totalEtapas,
        salvando: _salvando,
        onProximo: _proximaEtapa,
      ),
      ),
    );
  }
}

// --- SUB-WIDGETS COMPARTILHADOS ---

class _BarraProgressoModerno extends StatelessWidget {
  final int etapaAtual;
  final int total;
  const _BarraProgressoModerno({required this.etapaAtual, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(total, (i) {
          final ativo = i <= etapaAtual;
          return Expanded(
            child: AnimatedContainer(
              duration: 400.ms,
              height: 6,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: ativo ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BotoesNavegacao extends StatelessWidget {
  final int etapaAtual;
  final int total;
  final bool salvando;
  final VoidCallback onProximo;

  const _BotoesNavegacao({required this.etapaAtual, required this.total, required this.salvando, required this.onProximo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: BotaoPadrao(
              label: etapaAtual == total - 1 ? 'FINALIZAR' : 'PRÓXIMO',
              icone: etapaAtual == total - 1 ? IconesApp.salvar : Icons.arrow_forward_rounded,
              onPressed: salvando ? null : onProximo,
              carregando: salvando,
            ),
          ),
        ],
      ),
    );
  }
}

// --- PÁGINAS DO FORMULÁRIO ---

class _PaginaIdentificacao extends StatelessWidget {
  final TextEditingController brincoController;
  final TextEditingController nomeController;
  final String? piqueteSelecionadoId;
  final ValueChanged<String?> onPiqueteChanged;

  const _PaginaIdentificacao({required this.brincoController, required this.nomeController, required this.piqueteSelecionadoId, required this.onPiqueteChanged});

  @override
  Widget build(BuildContext context) {
    final piquetes = context.watch<ProvedorFazenda>().piquetes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(texto: 'Onde o animal está?', icone: IconesApp.piquete),
          CartaoPadrao(
            child: DropdownPadrao<String>(
              label: 'Piquete / Pasto *',
              icone: IconesApp.piquete,
              valorSelecionado: piqueteSelecionadoId,
              itens: piquetes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome))).toList(),
              onChanged: onPiqueteChanged,
            ),
          ),
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Identificação Única', icone: Icons.tag),
          CartaoPadrao(
            child: Column(
              children: [
                CampoFormularioPadrao(label: 'Nº do Brinco *', icone: Icons.tag, controller: brincoController, tipoTeclado: TextInputType.text),
                const SizedBox(height: 16),
                CampoFormularioPadrao(label: 'Nome (Opcional)', icone: Icons.abc, controller: nomeController),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}

class _PaginaCaracteristicas extends StatelessWidget {
  final TextEditingController racaController;
  final String sexo;
  final String categoria;
  final List<String> categorias;
  final DateTime dataNascimento;
  final ValueChanged<String> onSexoChanged;
  final ValueChanged<String> onCategoriaChanged;
  final VoidCallback onDataTap;

  const _PaginaCaracteristicas({required this.racaController, required this.sexo, required this.categoria, required this.categorias, required this.dataNascimento, required this.onSexoChanged, required this.onCategoriaChanged, required this.onDataTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(texto: 'Genética e Tipo', svgIcone: IconesApp.iconAnimalSvg),
          CartaoPadrao(
            child: Column(
              children: [
                _SeletorSexo(sexo: sexo, onChanged: onSexoChanged),
                const SizedBox(height: 20),
                CampoFormularioPadrao(label: 'Raça *', svgIcone: IconesApp.iconAnimalSvg, controller: racaController),
                const SizedBox(height: 16),
                DropdownPadrao<String>(
                  label: 'Categoria',
                  icone: Icons.category_outlined,
                  valorSelecionado: categoria,
                  itens: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => onCategoriaChanged(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Cronologia', icone: Icons.calendar_today),
          CartaoPadrao(
            child: CampoFormularioPadrao(
              label: 'Nascimento',
              icone: Icons.cake_outlined,
              soLeitura: true,
              controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(dataNascimento)),
              onTap: onDataTap,
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}

class _PaginaRevisao extends StatelessWidget {
  final TextEditingController pesoController;
  final String brinco;
  final String raca;
  final String? loteId;
  final String status;
  final DateTime? dataObito;
  final TextEditingController causaObitoController;
  final DateTime? dataSaida;
  final TextEditingController motivoSaidaController;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDataObitoTap;
  final VoidCallback onDataSaidaTap;

  const _PaginaRevisao({
    required this.pesoController,
    required this.brinco,
    required this.raca,
    required this.loteId,
    required this.status,
    required this.dataObito,
    required this.causaObitoController,
    required this.dataSaida,
    required this.motivoSaidaController,
    required this.onStatusChanged,
    required this.onDataObitoTap,
    required this.onDataSaidaTap,
  });

  @override
  Widget build(BuildContext context) {
    final piqueteNome = context.watch<ProvedorFazenda>().piquetes.firstWhere((p) => p.id == loteId, orElse: () => Piquete(id: loteId, fazendaId: '', nome: '—', tipo: '', capacidade: 0)).nome;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(texto: 'Peso de Entrada', icone: IconesApp.peso),
          CartaoPadrao(
            child: CampoFormularioPadrao(
              label: 'Peso Inicial (Kg)',
              icone: IconesApp.peso,
              controller: pesoController,
              tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Status do Animal', icone: Icons.info_outline),
          CartaoPadrao(
            child: DropdownPadrao<String>(
              label: 'Status',
              icone: Icons.info_outline,
              valorSelecionado: status,
              itens: const [
                DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                DropdownMenuItem(value: 'Morto', child: Text('Morto')),
                DropdownMenuItem(value: 'Vendido', child: Text('Vendido')),
              ],
              onChanged: (v) => onStatusChanged(v!),
            ),
          ),
          if (status == 'Morto') ...[
            const SizedBox(height: 16),
            CartaoPadrao(
              child: Column(
                children: [
                  CampoFormularioPadrao(
                    label: 'Data do Óbito *',
                    icone: Icons.calendar_today,
                    soLeitura: true,
                    controller: TextEditingController(text: dataObito != null ? DateFormat('dd/MM/yyyy').format(dataObito!) : 'Selecionar data'),
                    onTap: onDataObitoTap,
                  ),
                  const SizedBox(height: 16),
                  CampoFormularioPadrao(
                    label: 'Causa do Óbito',
                    icone: Icons.medical_services_outlined,
                    controller: causaObitoController,
                  ),
                ],
              ),
            ),
          ],
          if (status == 'Vendido') ...[
            const SizedBox(height: 16),
            CartaoPadrao(
              child: Column(
                children: [
                  CampoFormularioPadrao(
                    label: 'Data da Saída *',
                    icone: Icons.calendar_today,
                    soLeitura: true,
                    controller: TextEditingController(text: dataSaida != null ? DateFormat('dd/MM/yyyy').format(dataSaida!) : 'Selecionar data'),
                    onTap: onDataSaidaTap,
                  ),
                  const SizedBox(height: 16),
                  CampoFormularioPadrao(
                    label: 'Motivo da Saída',
                    icone: Icons.description_outlined,
                    controller: motivoSaidaController,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Resumo do Cadastro', icone: Icons.fact_check_outlined),
          CartaoPadrao(
            child: Column(
              children: [
                _ItemResumo(label: 'Brinco', valor: brinco, icon: Icons.tag),
                _ItemResumo(label: 'Raça', valor: raca, svgIcon: IconesApp.iconAnimalSvg),
                _ItemResumo(label: 'Status', valor: status, icon: status == 'Ativo' ? Icons.check_circle : Icons.cancel),
                _ItemResumo(label: 'Piquete', valor: piqueteNome, icon: IconesApp.piquete, isUltimo: true),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}

// --- COMPONENTES AUXILIARES ---

class _SeletorSexo extends StatelessWidget {
  final String sexo;
  final ValueChanged<String> onChanged;
  const _SeletorSexo({required this.sexo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotaoSexo(label: 'MACHO', icon: Icons.male, selecionado: sexo == 'M', cor: Colors.blue, onTap: () => onChanged('M')),
        const SizedBox(width: 12),
        _BotaoSexo(label: 'FÊMEA', icon: Icons.female, selecionado: sexo == 'F', cor: Colors.pink, onTap: () => onChanged('F')),
      ],
    );
  }
}

class _BotaoSexo extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selecionado;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoSexo({required this.label, required this.icon, required this.selecionado, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selecionado ? cor.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selecionado ? cor : theme.colorScheme.outlineVariant, width: selecionado ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selecionado ? cor : theme.colorScheme.outline, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selecionado ? cor : theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemResumo extends StatelessWidget {
  final String label;
  final String valor;
  final IconData? icon;
  final String? svgIcon;
  final bool isUltimo;

  const _ItemResumo({required this.label, required this.valor, this.icon, this.svgIcon, this.isUltimo = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (svgIcon != null)
                SvgPicture.asset(
                  svgIcon!,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        if (!isUltimo) Divider(color: Colors.grey.withValues(alpha: 0.1)),
      ],
    );
  }
}
