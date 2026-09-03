import 'package:flutter/material.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';

class BotoesNavegacao extends StatelessWidget {
  final int etapaAtual;
  final int total;
  final bool salvando;
  final VoidCallback onProximo;

  const BotoesNavegacao({super.key, required this.etapaAtual, required this.total, required this.salvando, required this.onProximo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: BotaoPadrao(
              label: etapaAtual == total - 1 ? 'FINALIZAR' : 'PRÓXIMO',
              icone: etapaAtual == total - 1 ? IconesApp.salvar : Icons.arrow_forward_rounded,
              onPressed: salvando ? null : onProximo,
              carregando: salvando,
            ),
          ),
        ],
      ),
    );
  }
}
