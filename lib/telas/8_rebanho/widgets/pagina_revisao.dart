import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/piquete.dart';
import '../../../provedores/provedor_fazenda.dart';
import 'item_resumo.dart';

class PaginaRevisao extends StatelessWidget {
  final TextEditingController pesoController;
  final String brinco;
  final String raca;
  final String? loteId;
  final String status;
  final DateTime? dataObito;
  final TextEditingController causaObitoController;
  final DateTime? dataSaida;
  final TextEditingController motivoSaidaController;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDataObitoTap;
  final VoidCallback onDataSaidaTap;

  const PaginaRevisao({
    super.key,
    required this.pesoController,
    required this.brinco,
    required this.raca,
    required this.loteId,
    required this.status,
    required this.dataObito,
    required this.causaObitoController,
    required this.dataSaida,
    required this.motivoSaidaController,
    required this.onStatusChanged,
    required this.onDataObitoTap,
    required this.onDataSaidaTap,
  });

  @override
  Widget build(BuildContext context) {
    final piqueteNome = context.watch<ProvedorFazenda>().piquetes.firstWhere((p) => p.id == loteId, orElse: () => Piquete(id: loteId, fazendaId: '', nome: '—', tipo: '', capacidade: 0)).nome;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SecaoTitulo(texto: 'Peso de Entrada', icone: IconesApp.peso),
          CartaoPadrao(
            child: CampoFormularioPadrao(
              label: 'Peso Inicial (Kg)',
              icone: IconesApp.peso,
              controller: pesoController,
              tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Status do Animal', icone: Icons.info_outline),
          CartaoPadrao(
            child: DropdownPadrao<String>(
              label: 'Status',
              icone: Icons.info_outline,
              valorSelecionado: status,
              itens: const [
                DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                DropdownMenuItem(value: 'Morto', child: Text('Morto')),
                DropdownMenuItem(value: 'Vendido', child: Text('Vendido')),
              ],
              onChanged: (v) => onStatusChanged(v!),
            ),
          ),
          if (status == 'Morto') ...[
            const SizedBox(height: 16),
            CartaoPadrao(
              child: Column(
                children: [
                  CampoFormularioPadrao(
                    label: 'Data do Óbito *',
                    icone: Icons.calendar_today,
                    soLeitura: true,
                    controller: TextEditingController(text: dataObito != null ? DateFormat('dd/MM/yyyy').format(dataObito!) : 'Selecionar data'),
                    onTap: onDataObitoTap,
                  ),
                  const SizedBox(height: 16),
                  CampoFormularioPadrao(
                    label: 'Causa do Óbito',
                    icone: Icons.medical_services_outlined,
                    controller: causaObitoController,
                  ),
                ],
              ),
            ),
          ],
          if (status == 'Vendido') ...[
            const SizedBox(height: 16),
            CartaoPadrao(
              child: Column(
                children: [
                  CampoFormularioPadrao(
                    label: 'Data da Saída *',
                    icone: Icons.calendar_today,
                    soLeitura: true,
                    controller: TextEditingController(text: dataSaida != null ? DateFormat('dd/MM/yyyy').format(dataSaida!) : 'Selecionar data'),
                    onTap: onDataSaidaTap,
                  ),
                  const SizedBox(height: 16),
                  CampoFormularioPadrao(
                    label: 'Motivo da Saída',
                    icone: Icons.description_outlined,
                    controller: motivoSaidaController,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SecaoTitulo(texto: 'Resumo do Cadastro', icone: Icons.fact_check_outlined),
          CartaoPadrao(
            child: Column(
              children: [
                ItemResumo(label: 'Brinco', valor: brinco, icon: Icons.tag),
                ItemResumo(label: 'Raça', valor: raca, svgIcon: IconesApp.iconAnimalSvg),
                ItemResumo(label: 'Status', valor: status, icon: status == 'Ativo' ? Icons.check_circle : Icons.cancel),
                ItemResumo(label: 'Piquete', valor: piqueteNome, icon: IconesApp.piquete, isUltimo: true),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.05, end: 0),
    );
  }
}
