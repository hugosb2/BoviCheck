import 'package:flutter/material.dart';
import '../../../modelos/piquete.dart';
import '../../8_rebanho/form_animal.dart';
import '../../10_formularios/form_pesagem.dart';
import '../../10_formularios/form_sanitario.dart';
import '../form_piquete.dart';
import 'piquete_ficha.dart';

class PiqueteAcoes extends StatelessWidget {
  final Piquete piquete;
  const PiqueteAcoes({super.key, required this.piquete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabelPiquete(texto: 'Ações Rápidas'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _BotaoAcao(icone: Icons.edit_outlined, label: 'Editar', cor: theme.colorScheme.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormPiquete(piqueteExistente: piquete))))),
        const SizedBox(width: 10),
        Expanded(child: _BotaoAcao(icone: Icons.add, label: 'Cadastrar\nAnimal', cor: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAnimal())))),
        const SizedBox(width: 10),
        Expanded(child: _BotaoAcao(icone: Icons.monitor_weight_outlined, label: 'Pesagem', cor: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPesagem())))),
        const SizedBox(width: 10),
        Expanded(child: _BotaoAcao(icone: Icons.medical_services_outlined, label: 'Sanitário', cor: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormSanitario())))),
      ]),
    ]);
  }
}

class _BotaoAcao extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color cor;
  final VoidCallback onTap;
  const _BotaoAcao({required this.icone, required this.label, required this.cor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))), child: Column(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icone, color: cor, size: 22)),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, height: 1.2), textAlign: TextAlign.center),
    ]))));
  }
}
