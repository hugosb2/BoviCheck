/// Documento da base de conhecimento para RAG.
class DocumentoRAG {
  final String id;
  final String titulo;
  final String conteudo;
  final List<String> tags;
  final String fonte;
  final String categoria;

  const DocumentoRAG({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.tags,
    required this.fonte,
    required this.categoria,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'conteudo': conteudo,
    'tags': tags,
    'fonte': fonte,
    'categoria': categoria,
  };
}

/// Resultado de retrieval com score.
class ResultadoRetrieval {
  final DocumentoRAG documento;
  final double score;

  const ResultadoRetrieval({required this.documento, required this.score});
}
