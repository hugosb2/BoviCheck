import 'modelo_documento.dart';
import 'retrieval_servico.dart';

/// Orquestra RAG: recupera docs relevantes e monta prompt aumentado.
class RAGService {
  final RetrievalService _retrieval;

  RAGService({RetrievalService? retrieval})
      : _retrieval = retrieval ?? RetrievalService();

  /// Recupera documentos relevantes para [dadosRebanho] e monta contexto.
  RagContext recuperarContexto(Map<String, dynamic> dadosRebanho, {int topK = 3}) {
    final query = _retrieval.construirQueryDeIndicadores(dadosRebanho);
    final resultados = _retrieval.recuperar(query, topK: topK);
    return RagContext(
      query: query,
      resultados: resultados,
      contextoFormatado: _formatarContexto(resultados),
    );
  }

  /// Monta o prompt final para Gemini com dados + contexto RAG.
  String construirPrompt(Map<String, dynamic> dadosRebanho, RagContext rag) {
    final dadosStr = _formatarDadosRebanho(dadosRebanho);

    return '''
Você é um consultor veterinário sênior especialista em pecuária de corte e leite no Brasil (Embrapa, CBRA, MAPA).

## DADOS DO REBANHO (tempo real do app)
$dadosStr

## CONTEXTO TÉCNICO RECUPERADO (RAG - base de conhecimento)
${rag.contextoFormatado.isEmpty ? 'Nenhum documento relevante recuperado.' : rag.contextoFormatado}

## INSTRUÇÕES
1. Analise os indicadores (GMD, IEP, natalidade, mortalidade, leite) comparando com os limiares dos documentos.
2. Cite explicitamente os documentos/fonte quando usar um limiar (ex: "Segundo Embrapa Gado de Corte - GMD ideal 0,70-0,90...").
3. Dê 3-5 recomendações práticas, priorizando o indicador mais crítico.
4. Se algum indicador estiver sem dados, diga "dados insuficientes" e não invente.
5. Responda em Markdown em português (pt-BR) com seções: Diagnóstico, Pontos de Atenção, Recomendações, Referências RAG.
6. Seja conciso e técnico, sem enrolação.

Gere a análise agora.
''';
  }

  String _formatarDadosRebanho(Map<String, dynamic> d) {
    final b = StringBuffer();
    b.writeln('- Fazenda: ${d['fazenda'] ?? '-'} (${d['local'] ?? '-'})');
    b.writeln('- Total animais: ${d['totalAnimais'] ?? 0} (ativos: ${d['totalAnimaisAtivos'] ?? 0})');
    if (d.containsKey('distribuicao')) {
      final dist = d['distribuicao'] as Map;
      b.writeln('- Distribuição: ${dist['machos'] ?? 0} machos, ${dist['femeas'] ?? 0} fêmeas');
    }
    if (d.containsKey('lotes')) {
      b.writeln('- Piquetes: ${(d['lotes'] as List).join(', ')}');
    }
    if (d.containsKey('indicadores')) {
      final ind = d['indicadores'] as Map<String, dynamic>;
      b.writeln('- Indicadores:');
      for (final e in ind.entries) {
        final v = e.value;
        final str = v is double ? v.toStringAsFixed(2) : v.toString();
        b.writeln('  • ${e.key}: $str');
      }
    }
    if (d.containsKey('animaisDoentes')) {
      b.writeln('- Animais com alerta sanitário (7d): ${d['animaisDoentes']}');
    }
    return b.toString();
  }

  String _formatarContexto(List<ResultadoRetrieval> resultados) {
    if (resultados.isEmpty) return '';
    final b = StringBuffer();
    for (var i = 0; i < resultados.length; i++) {
      final r = resultados[i];
      b.writeln('### [Doc ${i + 1}] ${r.documento.titulo} (score: ${r.score.toStringAsFixed(3)})');
      b.writeln('Fonte: ${r.documento.fonte} | Categoria: ${r.documento.categoria}');
      b.writeln(r.documento.conteudo);
      b.writeln('');
    }
    return b.toString();
  }
}

class RagContext {
  final String query;
  final List<ResultadoRetrieval> resultados;
  final String contextoFormatado;

  RagContext({
    required this.query,
    required this.resultados,
    required this.contextoFormatado,
  });
}
