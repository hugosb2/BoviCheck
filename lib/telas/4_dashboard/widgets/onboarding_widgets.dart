import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../9_piquetes/form_piquete.dart';
import '../../8_rebanho/form_animal.dart';
import 'package:provider/provider.dart';
import '../../../provedores/provedor_fazenda.dart';

class OnboardingPiquete extends StatelessWidget {
  const OnboardingPiquete({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'BoviCheck'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(IconesApp.piquete, size: 100, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 32),
          Text('Crie seu primeiro piquete', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text("Piquetes organizam seus animais por categoria, como 'Matrizes', 'Bezerros' ou 'Confinamento'.\n\nCrie ao menos um piquete para começar.", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
          const Spacer(),
          SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPiquete())); if (!context.mounted) return; await context.read<ProvedorFazenda>().carregarPropriedades(); }, icon: const Icon(Icons.add), label: const Text('Criar Piquete', style: TextStyle(fontSize: 18)))),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }
}

class OnboardingAnimal extends StatelessWidget {
  const OnboardingAnimal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'BoviCheck'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SvgPicture.asset(IconesApp.iconAnimalSvg, width: 100, height: 100, colorFilter: ColorFilter.mode(theme.colorScheme.primary.withValues(alpha: 0.3), BlendMode.srcIn)),
          const SizedBox(height: 32),
          Text('Cadastre seu primeiro animal', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Agora cadastre os animais do seu rebanho. Informe brinco, nome, raça, data de nascimento e muito mais.', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
          const Spacer(),
          SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAnimal())); if (!context.mounted) return; await context.read<ProvedorFazenda>().carregarPropriedades(); }, icon: const Icon(Icons.add), label: const Text('Cadastrar Animal', style: TextStyle(fontSize: 18)))),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }
}
