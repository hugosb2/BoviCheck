import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../10_formularios/form_pesagem.dart';
import '../../10_formularios/form_sanitario.dart';
import '../../10_formularios/form_reprodutivo.dart';
import '../../10_formularios/form_leite.dart';
import '../../10_formularios/form_abate.dart';

class GridAcoesRapidas extends StatelessWidget {
  const GridAcoesRapidas({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _BotaoAcao(context, 'Pesagem', IconesApp.peso, Colors.indigo, const FormPesagem())),
        const SizedBox(width: 12),
        Expanded(child: _BotaoAcao(context, 'Saúde', IconesApp.vacina, Colors.red, const FormSanitario())),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _BotaoAcao(context, 'Reprodução', IconesApp.reproducao, Colors.pink, const FormReprodutivo())),
        const SizedBox(width: 12),
        Expanded(child: _BotaoAcao(context, 'Leite', IconesApp.leite, Colors.blue, const FormLeite())),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _BotaoAcao(context, 'Abate', Icons.restaurant, Colors.brown, const FormAbate())),
        const Expanded(child: SizedBox.shrink()),
      ]),
    ]);
  }

  Widget _BotaoAcao(BuildContext context, String label, IconData icone, Color cor, Widget destino) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withValues(alpha: 0.2), width: 1.2)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icone, color: cor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface))),
          Icon(Icons.chevron_right_rounded, color: cor.withValues(alpha: 0.4), size: 22),
        ]),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }
}
