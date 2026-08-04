import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';

class TelaSobre extends StatefulWidget {
  const TelaSobre({super.key});

  @override
  State<TelaSobre> createState() => _TelaSobreState();
}

class _TelaSobreState extends State<TelaSobre> {
  String _versao = '';
  String _buildNumber = '';
  String _appName = 'BoviCheck';

  @override
  void initState() {
    super.initState();
    _carregarInfo();
  }

  Future<void> _carregarInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versao = info.version;
      _buildNumber = info.buildNumber;
      _appName = info.appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarPadrao(titulo: 'Sobre'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(IconesApp.logoApp, fit: BoxFit.contain),
              ),

              const SizedBox(height: 24),

              Text(
                _appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Versão $_versao (Build $_buildNumber)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              const _CardInfo(
                titulo: 'Desenvolvedor',
                valor: 'Hugo Santos Barros (Estudante)',
                subtitulo: 'hugobs4987@gmail.com',
              ),
              const _CardInfo(
                titulo: 'Orientador',
                valor: 'Francisco Hélio de Oliveira (Docente)',
                subtitulo: 'francisco.oliveira@ifbaiano.edu.br',
              ),
              const _CardInfo(
                titulo: 'Coorientador',
                valor: 'Hudson Barros Oliveira (Docente)',
                subtitulo: 'hudson.barros@ifbaiano.edu.br',
              ),
              const _CardInfo(
                titulo: 'Colaboradora',
                valor: 'Jacqueline Firmino de Sá (Docente)',
                subtitulo: 'Aguardando contato',
              ),

              const SizedBox(height: 24),

              Text(
                'Instituto Federal Baiano — Campus Itapetinga',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              Image.asset('assets/iflogo.png', height: 60, fit: BoxFit.contain),

              const SizedBox(height: 48),

              Text(
                '© ${DateTime.now().year} BoviCheck. Todos os direitos reservados.',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;

  const _CardInfo({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(titulo, style: const TextStyle(fontSize: 12)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitulo, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.2, end: 0, duration: 400.ms);
  }
}
