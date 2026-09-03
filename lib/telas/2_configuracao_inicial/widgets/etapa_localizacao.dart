import 'package:flutter/material.dart';
import '../../../estilos/icones.dart';

class EtapaLocalizacao extends StatelessWidget {
  final TextEditingController cepController;
  final TextEditingController cidadeController;
  final String? estadoSelecionado;
  final List<String> estados;
  final bool buscandoCep;
  final Function(String) onBuscarCep;
  final Function(String?) onEstadoChanged;
  final InputDecoration Function(String, IconData, {String? suffix}) inputDecor;
  const EtapaLocalizacao({super.key, required this.cepController, required this.cidadeController, required this.estadoSelecionado, required this.estados, required this.buscandoCep, required this.onBuscarCep, required this.onEstadoChanged, required this.inputDecor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Onde fica sua fazenda?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Informe a localização para melhor gestão.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 32),
      TextFormField(
        controller: cepController,
        decoration: inputDecor('CEP', Icons.location_on_outlined).copyWith(
          suffixIcon: buscandoCep ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(icon: const Icon(Icons.search), onPressed: () => onBuscarCep(cepController.text.replaceAll('-', '').replaceAll(' ', ''))),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final cepNumerico = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (cepNumerico.length == 8) onBuscarCep(cepNumerico);
          if (value.length == 5 && !value.contains('-')) {
            cepController.text = '$value-';
            cepController.selection = TextSelection.fromPosition(TextPosition(offset: cepController.text.length));
          }
        },
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(flex: 3, child: TextFormField(controller: cidadeController, decoration: inputDecor('Cidade', IconesApp.localizacao))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: DropdownButtonFormField<String>(initialValue: estadoSelecionado, decoration: inputDecor('UF', Icons.map), isExpanded: true, items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onEstadoChanged)),
      ]),
    ]));
  }
}
