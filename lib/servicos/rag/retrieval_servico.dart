import 'dart:math';
import 'modelo_documento.dart';
import 'base_conhecimento.dart';

/// RetrievalService local sem dependência de API de embeddings.
/// Implementa TF-IDF + Cosine Similarity puramente em Dart (offline-first).
/// Opcionalmente pode delegar para Gemini Embeddings quando `usarEmbeddings=true`.
class RetrievalService {
  final List<DocumentoRAG> _docs;

  RetrievalService({List<DocumentoRAG>? documentos})
      : _docs = documentos ?? BaseConhecimento.documentos;

  /// Recupera topK documentos mais relevantes para a [query].
  /// Usa TF-IDF + cosine similarity. Retorna ordenado por score desc.
  List<ResultadoRetrieval> recuperar(String query, {int topK = 3}) {
    if (query.trim().isEmpty) return [];
    final queryTokens = _tokenizar(query);
    if (queryTokens.isEmpty) return [];

    // Pré-calcula IDF para todos os termos do corpus + query
    final todosTokens = <String>{...queryTokens};
    for (final d in _docs) {
      todosTokens.addAll(_tokenizar('${d.titulo} ${d.conteudo} ${d.tags.join(' ')}'));
    }

    final idf = <String, double>{};
    final nDocs = _docs.length;
    for (final token in todosTokens) {
      final df = _docs.where((d) {
        final docTokens = _tokenizar('${d.titulo} ${d.conteudo} ${d.tags.join(' ')}');
        return docTokens.contains(token);
      }).length;
      // Suavizado: evita divisão por zero
      idf[token] = log((nDocs + 1) / (df + 1)) + 1;
    }

    // Vetor TF-IDF da query
    final queryTf = _tf(queryTokens);
    final queryVec = <String, double>{};
    for (final t in queryTf.keys) {
      queryVec[t] = queryTf[t]! * (idf[t] ?? 1.0);
    }
    final queryNorm = _norma(queryVec);

    final resultados = <ResultadoRetrieval>[];
    for (final doc in _docs) {
      final docText = '${doc.titulo} ${doc.conteudo} ${doc.tags.join(' ')} ${doc.categoria}';
      final docTokens = _tokenizar(docText);
      final docTf = _tf(docTokens);
      final docVec = <String, double>{};
      for (final t in docTf.keys) {
        docVec[t] = docTf[t]! * (idf[t] ?? 1.0);
      }
      // Boost por tags exatas (RAG híbrido)
      double boost = 1.0;
      for (final tag in doc.tags) {
        if (queryTokens.contains(tag.toLowerCase())) boost += 0.25;
      }

      final score = _cosine(queryVec, docVec, queryNorm) * boost;
      if (score > 0.01) {
        resultados.add(ResultadoRetrieval(documento: doc, score: score));
      }
    }

    resultados.sort((a, b) => b.score.compareTo(a.score));
    return resultados.take(topK).toList();
  }

  /// Constrói query textual a partir dos indicadores do rebanho.
  String construirQueryDeIndicadores(Map<String, dynamic> dados) {
    final buff = StringBuffer();
    buff.write('${dados['fazenda'] ?? ''} ');
    buff.write('total ${dados['totalAnimais'] ?? 0} animais ativos ${dados['totalAnimaisAtivos'] ?? 0} ');

    // Adiciona termos baseados em indicadores críticos
    if (dados.containsKey('indicadores')) {
      final ind = dados['indicadores'] as Map<String, dynamic>;
      for (final e in ind.entries) {
        final v = e.value;
        if (v is num) {
          buff.write('${e.key} ${v.toStringAsFixed(2)} ');
          // Palavras-chave para forçar retrieval correto
          if (e.key.toLowerCase().contains('gmd') && v < 0.5) {
            buff.write('gmd baixo ganho peso suplementação ');
          }
          if (e.key.toLowerCase().contains('iep') && v > 14) {
            buff.write('iep intervalo parto reprodução ');
          }
          if (e.key.toLowerCase().contains('mortalidade') && v > 3) {
            buff.write('mortalidade sanidade vacina óbito ');
          }
          if (e.key.toLowerCase().contains('natalidade') && v < 60) {
            buff.write('natalidade prenhez fertilidade ');
          }
          if (e.key.toLowerCase().contains('leite')) {
            buff.write('leite produção litros ');
          }
        }
      }
    }

    if (dados.containsKey('animaisDoentes') && (dados['animaisDoentes'] as int) > 0) {
      buff.write('sanidade vacina doença verminose ');
    }

    // Fallback: usa também tags genéricas
    if (buff.length < 10) {
      buff.write('manejo pecuária corte leite reprodução sanidade ');
    }

    return buff.toString();
  }

  // --- Helpers TF-IDF ---

  List<String> _tokenizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áàâãéèêíïóôõöúçñ\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !_stopwords.contains(t))
        .toList();
  }

  Map<String, double> _tf(List<String> tokens) {
    final freq = <String, int>{};
    for (final t in tokens) {
      freq[t] = (freq[t] ?? 0) + 1;
    }
    final total = tokens.length;
    return freq.map((k, v) => MapEntry(k, v / total));
  }

  double _norma(Map<String, double> vec) {
    double sum = 0;
    for (final v in vec.values) {
      sum += v * v;
    }
    return sqrt(sum);
  }

  double _cosine(Map<String, double> a, Map<String, double> b, double normA) {
    if (normA == 0) return 0;
    final normB = _norma(b);
    if (normB == 0) return 0;
    double dot = 0;
    for (final k in a.keys) {
      if (b.containsKey(k)) dot += a[k]! * b[k]!;
    }
    return dot / (normA * normB);
  }

  static const _stopwords = {
    'para', 'com', 'por', 'uma', 'uns', 'umas', 'que', 'dos', 'das',
    'nos', 'nas', 'como', 'mais', 'mas', 'foi', 'ser', 'são', 'tem',
    'the', 'and', 'for', 'are', 'seu', 'sua', 'seus', 'suas',
    'este', 'esta', 'isso', 'esse', 'essa', 'entre', 'sobre', 'após',
    'de', 'da', 'do', 'em', 'no', 'na', 'ao', 'os', 'as', 'um', 'o', 'a', 'e',
  };
}
