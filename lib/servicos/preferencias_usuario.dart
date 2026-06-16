import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Representa as preferências do usuário conforme o diagrama de classes.
class PreferenciasUsuario {
  final String id;
  final String temaApp; // 'light', 'dark' ou 'system'
  final String corDestaque;
  final bool notificacoesAtivas;
  final bool lembrarSenha;
  final String idioma;

  static const _keyUltimaFazenda = 'ultima_fazenda_id';

  PreferenciasUsuario({
    String? id,
    this.temaApp = 'system',
    this.corDestaque = '#4CAF50',
    this.notificacoesAtivas = true,
    this.lembrarSenha = false,
    this.idioma = 'pt_BR',
  }) : id = id ?? 'default';

  Future<void> salvarUltimaFazenda(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimaFazenda, id);
  }

  Future<String?> carregarUltimaFazenda() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUltimaFazenda);
  }

  /// Converte o temaApp string para ThemeMode do Flutter.
  ThemeMode get themeMode {
    switch (temaApp) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

