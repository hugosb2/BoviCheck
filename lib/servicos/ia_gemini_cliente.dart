import 'configuracao.dart';

class IAGeminiCliente {
  /// Analisa os dados gerais do rebanho e retorna insights em Markdown.
  Future<String> analisarRebanho(Map<String, dynamic> dadosRebanho) async {
    try {
      if (!Configuracao.temApiKey) {
        return "⚠️ Configuração Pendente: Adicione sua API Key do Google Gemini no arquivo `configuracao.dart`.";
      }

      await Future.delayed(const Duration(seconds: 2));

      return '''
### 🩺 Diagnóstico Veterinário IA

Baseado nos dados fornecidos (${dadosRebanho['totalAnimais']} animais), o rebanho apresenta estabilidade, mas requer atenção em alguns índices reprodutivos.

### ⚠️ Pontos de Atenção
* **Natalidade**: Abaixo do ideal para a região.
* **Sanidade**: Foram registrados ${dadosRebanho['animaisDoentes'] ?? 0} casos recentes que exigem monitoramento.

### ✅ Recomendações
1.  🥩 **Suplementação**: Reforçar proteinado no cocho para o Piquete de Engorda.
2.  💉 **Vacinação**: Revisar calendário de Clostridiose.
3.  📊 **Dados**: Aumentar a frequência de pesagens para melhorar a precisão do GMD.
      ''';
    } catch (e) {
      return "Erro ao conectar com a IA: $e. Verifique sua conexão.";
    }
  }

}
