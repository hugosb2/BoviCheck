import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../estilos/icones.dart';
import '../../../modelos/animal.dart';

class AnimalPesoCard extends StatelessWidget {
  final Animal animal;
  const AnimalPesoCard({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SecaoLabelPeso(texto: 'Peso Atual'),
      const SizedBox(height: 14),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24), decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primaryContainer.withValues(alpha: 0.6), theme.colorScheme.primaryContainer.withValues(alpha: 0.2)], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(IconesApp.peso, size: 40, color: theme.colorScheme.primary),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(animal.pesoAtualKg.toStringAsFixed(1), style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, height: 1)),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('kg', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4),
            Row(children: [Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text('Nascimento: ${DateFormat('dd/MM/yyyy').format(animal.dataNascimento)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))]),
            Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('ID: ${animal.id.length > 8 ? '${animal.id.substring(0, 8)}...' : animal.id}', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: theme.colorScheme.primary.withValues(alpha: 0.6)))),
          ]),
        ]),
      ),
    ]));
  }
}

class SecaoLabelPeso extends StatelessWidget {
  final String texto;
  const SecaoLabelPeso({super.key, required this.texto});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [Container(width: 4, height: 20, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(texto, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]);
  }
}
