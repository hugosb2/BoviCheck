import 'package:flutter/material.dart';

class PeriodoChip extends StatelessWidget {
  final String label;
  final int dias;
  final DateTimeRange atual;
  final Function(int) onSelected;
  const PeriodoChip(this.label, this.dias, this.atual, this.onSelected, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = atual.end.difference(atual.start).inDays;
    final isSelected = (diff - dias).abs() <= 1;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label), selected: isSelected, onSelected: (_) => onSelected(dias),
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        checkmarkColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
