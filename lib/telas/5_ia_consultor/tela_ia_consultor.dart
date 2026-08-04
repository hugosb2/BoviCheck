import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../estilos/cores.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/ia_gemini_cliente.dart';

class TelaIAConsultor extends StatefulWidget {
  const TelaIAConsultor({super.key});

  @override
  State<TelaIAConsultor> createState() => _TelaIAConsultorState();
}

class _TelaIAConsultorState extends State<TelaIAConsultor> {
  bool _carregando = false;
  String? _analiseResultado;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gerarAnalise();
    });
  }

  Future<void> _gerarAnalise() async {
    final provedor = context.read<ProvedorFazenda>();

    if (provedor.propriedadeAtiva == null) {
      setState(() {
        _analiseResultado =
            'Nenhuma fazenda selecionada. Volte para a tela inicial e selecione uma fazenda.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dadosParaIA = {
        'fazenda': provedor.propriedadeAtiva!.nomeFazenda,
        'local':
            '${provedor.propriedadeAtiva!.cidade}/${provedor.propriedadeAtiva!.estado}',
        'totalAnimais': provedor.totalAnimais,
        'distribuicao': {
          'machos': provedor.animais.where((a) => a.sexo == 'M').length,
          'femeas': provedor.animais.where((a) => a.sexo == 'F').length,
        },
        'lotes': provedor.piquetes.map((p) => p.nome).toList(),
      };

      final resultado = await IAGeminiCliente().analisarRebanho(dadosParaIA);

      if (mounted) {
        setState(() {
          _analiseResultado = resultado;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível conectar ao consultor virtual.\nErro: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarPadrao(titulo: 'Consultor IA'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ), // CORREÇÃO
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CoresApp.containerAtencao,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconesApp.iaConsultor,
                    color: CoresApp.atencao,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inteligência Veterinária',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analiso seus dados para sugerir melhorias de manejo.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _carregando
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        // CORREÇÃO DA ANIMAÇÃO: Usando shimmer ao invés de callback complexo
                        Text(
                              'Analisando rebanho...',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1.seconds),
                        const SizedBox(height: 8),
                        Text(
                          'Isso pode levar alguns segundos.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : _erro != null
                ? Center(child: Text(_erro!))
                : Markdown(
                    data: _analiseResultado ?? '',
                    padding: const EdgeInsets.all(24),
                    styleSheet: MarkdownStyleSheet(
                      h1: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      h2: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      // Removido parâmetro marginTop que não existia na versão da lib
                      blockquoteDecoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(),
          ),
        ],
      ),
    );
  }
}
