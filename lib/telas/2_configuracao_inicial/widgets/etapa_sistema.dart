import 'package:flutter/material.dart';

class EtapaSistema extends StatelessWidget {
  final String sistemaProducao;
  final List<String> sistemas;
  final TextEditingController areaController;
  final Function(String?) onSistemaChanged;
  final InputDecoration Function(String, IconData, {String? suffix}) inputDecor;
  const EtapaSistema({super.key, required this.sistemaProducao, required this.sistemas, required this.areaController, required this.onSistemaChanged, required this.inputDecor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Último passo!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Complete com informações do sistema de produção.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 32),
      DropdownButtonFormField<String>(initialValue: sistemaProducao, decoration: inputDecor('Sistema de Produção', Icons.settings_input_component), items: sistemas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: onSistemaChanged),
      const SizedBox(height: 16),
      TextFormField(controller: areaController, decoration: inputDecor('Área Total', Icons.aspect_ratio, suffix: 'ha'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
    ]));
  }
}
