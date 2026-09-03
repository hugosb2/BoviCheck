import 'package:flutter_dotenv/flutter_dotenv.dart';

class Configuracao {
  static String get geminiApiKey {
    try {
      return dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get temApiKey => geminiApiKey.isNotEmpty;
}
