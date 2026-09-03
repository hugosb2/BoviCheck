import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeletorSexo extends StatelessWidget {
  final String sexo;
  final ValueChanged<String> onChanged;
  const SeletorSexo({super.key, required this.sexo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotaoSexo(label: 'MACHO', icon: Icons.male, selecionado: sexo == 'M', cor: Colors.blue, onTap: () => onChanged('M')),
        const SizedBox(width: 12),
        _BotaoSexo(label: 'FÊMEA', icon: Icons.female, selecionado: sexo == 'F', cor: Colors.pink, onTap: () => onChanged('F')),
      ],
    );
  }
}

class _BotaoSexo extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selecionado;
  final Color cor;
  final VoidCallback onTap;

  const _BotaoSexo({required this.label, required this.icon, required this.selecionado, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selecionado ? cor.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selecionado ? cor : theme.colorScheme.outlineVariant, width: selecionado ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selecionado ? cor : theme.colorScheme.outline, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selecionado ? cor : theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
