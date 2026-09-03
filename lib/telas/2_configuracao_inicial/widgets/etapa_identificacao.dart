import 'package:flutter/material.dart';
import '../../../estilos/icones.dart';

class EtapaIdentificacao extends StatelessWidget {
  final TextEditingController nomeFazendaController;
  final TextEditingController proprietarioController;
  final InputDecoration Function(String, IconData, {String? suffix}) inputDecor;
  const EtapaIdentificacao({super.key, required this.nomeFazendaController, required this.proprietarioController, required this.inputDecor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Vamos começar!\nQual é o nome da sua fazenda?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Informe os dados básicos da propriedade.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 32),
      TextFormField(controller: nomeFazendaController, decoration: inputDecor('Nome da Fazenda', IconesApp.fazenda), textInputAction: TextInputAction.next),
      const SizedBox(height: 16),
      TextFormField(controller: proprietarioController, decoration: inputDecor('Nome do Proprietário', IconesApp.proprietario), textInputAction: TextInputAction.done),
    ]));
  }
}
