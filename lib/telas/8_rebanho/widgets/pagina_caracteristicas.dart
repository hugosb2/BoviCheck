import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import 'seletor_sexo.dart';

class PaginaCaracteristicas extends StatelessWidget {
  final TextEditingController racaController;
  final String sexo;
  final String categoria;
  final List<String> categorias;
  final DateTime dataNascimento;
  final ValueChanged<String> onSexoChanged;
  final ValueChanged<String> onCategoriaChanged;
  final VoidCallback onDataTap;

  const PaginaCaracteristicas({super.key, required this.racaController, required this.sexo, required this.categoria, required this.categorias, required this.dataNascimento, required this.onSexoChanged, required this.onCategoriaChanged, required this.onDataTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(texto: 'Genética e Tipo', svgIcone: IconesApp.iconAnimalSvg),
          CartaoPadrao(
            child: Column(
              children: [
                SeletorSexo(sexo: sexo, onChanged: onSexoChanged),
                const SizedBox(height: 20),
                CampoFormularioPadrao(label: 'Raça *', svgIcone: IconesApp.iconAnimalSvg, controller: racaController),
                const SizedBox(height: 16),
                DropdownPadrao<String>(
                  label: 'Categoria',
                  icone: Icons.category_outlined,
                  valorSelecionado: categoria,
                  itens: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => onCategoriaChanged(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Cronologia', icone: Icons.calendar_today),
          CartaoPadrao(
            child: CampoFormularioPadrao(
              label: 'Nascimento',
              icone: Icons.cake_outlined,
              soLeitura: true,
              controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(dataNascimento)),
              onTap: onDataTap,
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}
