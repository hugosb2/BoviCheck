import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../estilos/cores.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../servicos/ia_gemini_cliente.dart';
import '../../servicos/rag/modelo_documento.dart';

class TelaIAConsultor extends StatefulWidget {
  const TelaIAConsultor({super.key});

  @override
  State<TelaIAConsultor> createState() => _TelaIAConsultorState();
}

class _TelaIAConsultorState extends State<TelaIAConsultor> {
  bool _carregando = false;
  String? _analiseResultado;
  List<DocumentoRAG> _fontes = [];
  List<double> _scores = [];
  bool _usouRAG = false;
  bool _usouGemini = false;
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
        'totalAnimaisAtivos': provedor.totalAnimaisAtivos,
        'distribuicao': {
          'machos': provedor.animais.where((a) => a.sexo == 'M').length,
          'femeas': provedor.animais.where((a) => a.sexo == 'F').length,
        },
        'lotes': provedor.piquetes.map((p) => p.nome).toList(),
        // Indicadores para RAG
        'animaisDoentes': provedor.totalAnimaisDoentes,
        'indicadores': {
          'taxaMortalidade': provedor.taxaMortalidade,
          'mediaGMD': provedor.mediaGMD,
          'totalLeiteMes': provedor.totalLeiteMes,
          'totalNascimentos': provedor.totalNascimentos.toDouble(),
        },
      };

      final resultado = await IAGeminiCliente().analisarRebanhoComRAG(dadosParaIA);

      if (mounted) {
        setState(() {
          _analiseResultado = resultado.texto;
          _fontes = resultado.fontes;
          _scores = resultado.retrievals.map((r) => r.score).toList();
          _usouRAG = resultado.usouRAG;
          _usouGemini = resultado.usouGemini;
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
                        Text(
                              'Analisando rebanho com RAG...',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1.seconds),
                        const SizedBox(height: 8),
                        Text(
                          'Recuperando contexto técnico + Gemini.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : _erro != null
                ? Center(child: Text(_erro!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges RAG/Gemini
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(_usouRAG ? 'RAG: ON' : 'RAG: OFF'),
                              backgroundColor: _usouRAG
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              avatar: Icon(
                                _usouRAG ? Icons.library_books : Icons.library_books_outlined,
                                size: 18,
                              ),
                            ),
                            Chip(
                              label: Text(_usouGemini ? 'Gemini: ON' : 'Offline'),
                              backgroundColor: _usouGemini
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.orange.shade100,
                              avatar: Icon(
                                _usouGemini ? Icons.cloud_done : Icons.cloud_off,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        MarkdownBody(
                          data: _analiseResultado ?? '',
                          styleSheet: MarkdownStyleSheet(
                            h1: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            h2: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                        ),
                        if (_fontes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Divider(color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Fontes Recuperadas (RAG)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_fontes.length, (i) {
                            final doc = _fontes[i];
                            final score = i < _scores.length ? _scores[i] : 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          doc.titulo,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'score ${score.toStringAsFixed(3)}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${doc.fonte} • ${doc.categoria}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    doc.conteudo,
                                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: doc.tags
                                        .map((t) => Chip(
                                              label: Text(t, style: const TextStyle(fontSize: 10)),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ).animate().fadeIn(),
                  ),
          ),
        ],
      ),
    );
  }
}
