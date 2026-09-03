import 'dart:convert';
import 'package:http/http.dart' as http;
import 'configuracao.dart';
import 'rag/rag_servico.dart';
import 'rag/modelo_documento.dart';

class ResultadoIA {
  final String texto;
  final List<DocumentoRAG> fontes;
  final List<ResultadoRetrieval> retrievals;
  final bool usouRAG;
  final bool usouGemini;

  ResultadoIA({
    required this.texto,
    required this.fontes,
    required this.retrievals,
    required this.usouRAG,
    required this.usouGemini,
  });
}

class IAGeminiCliente {
  final RAGService _ragService;

  IAGeminiCliente({RAGService? ragService})
      : _ragService = ragService ?? RAGService();

  /// Fluxo RAG completo: recupera contexto + chama Gemini.
  /// Mantém compatibilidade com assinatura antiga (retorna só String).
  Future<String> analisarRebanho(Map<String, dynamic> dadosRebanho) async {
    final res = await analisarRebanhoComRAG(dadosRebanho);
    return res.texto;
  }

  /// Versão rica: retorna texto + fontes para a UI exibir referências.
  Future<ResultadoIA> analisarRebanhoComRAG(Map<String, dynamic> dadosRebanho) async {
    // 1. Retrieval
    final ragContext = _ragService.recuperarContexto(dadosRebanho, topK: 3);
    final prompt = _ragService.construirPrompt(dadosRebanho, ragContext);

    // 2. Se sem API key, fallback local com RAG (offline-first)
    if (!Configuracao.temApiKey) {
      final fallback = _gerarFallbackLocal(dadosRebanho, ragContext);
      return ResultadoIA(
        texto: fallback,
        fontes: ragContext.resultados.map((r) => r.documento).toList(),
        retrievals: ragContext.resultados,
        usouRAG: ragContext.resultados.isNotEmpty,
        usouGemini: false,
      );
    }

    // 3. Chama Gemini com prompt aumentado
    try {
      final resposta = await _chamarGemini(prompt);
      return ResultadoIA(
        texto: resposta,
        fontes: ragContext.resultados.map((r) => r.documento).toList(),
        retrievals: ragContext.resultados,
        usouRAG: ragContext.resultados.isNotEmpty,
        usouGemini: true,
      );
    } catch (e) {
      // Fallback em caso de erro de rede/quota
      final fallback = '${_gerarFallbackLocal(dadosRebanho, ragContext)}\n\n> ⚠️ Falha ao chamar Gemini ($e). Exibindo análise local com RAG.';
      return ResultadoIA(
        texto: fallback,
        fontes: ragContext.resultados.map((r) => r.documento).toList(),
        retrievals: ragContext.resultados,
        usouRAG: ragContext.resultados.isNotEmpty,
        usouGemini: false,
      );
    }
  }

  Future<String> _chamarGemini(String prompt) async {
    final apiKey = Configuracao.geminiApiKey;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024,
      }
    });

    final resp = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('Gemini ${resp.statusCode}: ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Resposta vazia do Gemini');
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) throw Exception('Sem parts na resposta');
    return parts.first['text'] as String? ?? 'Sem resposta';
  }

  /// Fallback 100% offline que já usa RAG para dar valor mesmo sem API.
  String _gerarFallbackLocal(Map<String, dynamic> dados, RagContext rag) {
    final total = dados['totalAnimais'] ?? 0;
    final ativos = dados['totalAnimaisAtivos'] ?? 0;
    final doentes = dados['animaisDoentes'] ?? 0;

    final b = StringBuffer();
    b.writeln('### 🩺 Diagnóstico Veterinário IA (RAG Offline)');
    b.writeln('');
    b.writeln('Rebanho: **$ativos ativos / $total total**.');
    if (doentes > 0) {
      b.writeln('⚠️ **$doentes animal(is) com alerta sanitário nos últimos 7 dias.**');
    }
    b.writeln('');

    if (rag.resultados.isEmpty) {
      b.writeln('### ⚠️ Pontos de Atenção');
      b.writeln('* Dados insuficientes para retrieval. Registre pesagens, partos e leite regularmente.');
    } else {
      b.writeln('### 📚 Contexto Técnico Recuperado (RAG)');
      for (final r in rag.resultados) {
        b.writeln('- **${r.documento.titulo}** (${r.documento.fonte}) — score ${r.score.toStringAsFixed(3)}');
      }
      b.writeln('');
      b.writeln('### ⚠️ Pontos de Atenção');
      for (final r in rag.resultados) {
        // Gera insight específico por categoria
        if (r.documento.categoria.contains('Crescimento') || r.documento.id.contains('gmd')) {
          b.writeln('* **GMD**: ${r.documento.conteudo.substring(0, 120)}...');
        } else if (r.documento.categoria.contains('Reprodução')) {
          b.writeln('* **Reprodução**: ${r.documento.conteudo.substring(0, 120)}...');
        } else if (r.documento.categoria.contains('Sanidade')) {
          b.writeln('* **Sanidade**: ${r.documento.conteudo.substring(0, 120)}...');
        } else {
          b.writeln('* **${r.documento.categoria}**: ${r.documento.conteudo.substring(0, 100)}...');
        }
      }
    }

    b.writeln('');
    b.writeln('### ✅ Recomendações');
    b.writeln('1. 🥩 Verificar suplementação se GMD <0,50 kg/dia (ver doc GMD).');
    b.writeln('2. 💉 Revisar calendário sanitário: Aftosa + Clostridioses (ver doc Sanitário).');
    b.writeln('3. 📊 Registrar pesagens a cada 30d e diagnóstico de prenhez 30d pós-IATF.');
    b.writeln('');
    b.writeln('### 📖 Referências RAG');
    if (rag.resultados.isEmpty) {
      b.writeln('_Nenhuma fonte recuperada._');
    } else {
      for (final r in rag.resultados) {
        b.writeln('- ${r.documento.titulo} — *${r.documento.fonte}*');
      }
    }
    b.writeln('');
    b.writeln('> ℹ️ Modo offline: configure `GEMINI_API_KEY` no `.env` para análise generativa completa com RAG + Gemini 1.5 Flash.');

    return b.toString();
  }
}
