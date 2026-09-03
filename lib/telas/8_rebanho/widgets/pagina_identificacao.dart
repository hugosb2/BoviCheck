import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../provedores/provedor_fazenda.dart';

class PaginaIdentificacao extends StatelessWidget {
  final TextEditingController brincoController;
  final TextEditingController nomeController;
  final String? piqueteSelecionadoId;
  final ValueChanged<String?> onPiqueteChanged;

  const PaginaIdentificacao({super.key, required this.brincoController, required this.nomeController, required this.piqueteSelecionadoId, required this.onPiqueteChanged});

  @override
  Widget build(BuildContext context) {
    final piquetes = context.watch<ProvedorFazenda>().piquetes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(texto: 'Onde o animal está?', icone: IconesApp.piquete),
          CartaoPadrao(
            child: DropdownPadrao<String>(
              label: 'Piquete / Pasto *',
              icone: IconesApp.piquete,
              valorSelecionado: piqueteSelecionadoId,
              itens: piquetes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome))).toList(),
              onChanged: onPiqueteChanged,
            ),
          ),
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Identificação Única', icone: Icons.tag),
          CartaoPadrao(
            child: Column(
              children: [
                CampoFormularioPadrao(label: 'Nº do Brinco *', icone: Icons.tag, controller: brincoController, tipoTeclado: TextInputType.text),
                const SizedBox(height: 16),
                CampoFormularioPadrao(label: 'Nome (Opcional)', icone: Icons.abc, controller: nomeController),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}
