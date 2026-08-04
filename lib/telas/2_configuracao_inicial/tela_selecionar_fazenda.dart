import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../estilos/icones.dart';
import '../../estilos/tema.dart';
import '../../provedores/provedor_fazenda.dart';
import '../../modelos/propriedade.dart';
import '../4_dashboard/tela_dashboard.dart';
import 'form_dados_fazenda.dart';
import 'tela_restaurar.dart';

class TelaSelecionarFazenda extends StatefulWidget {
  const TelaSelecionarFazenda({super.key});

  @override
  State<TelaSelecionarFazenda> createState() => _TelaSelecionarFazendaState();
}

class _TelaSelecionarFazendaState extends State<TelaSelecionarFazenda> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProvedorFazenda>().carregarPropriedades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final fazendas = provedor.propriedades;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(
        titulo: 'BoviCheck',
        centralizar: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => provedor.carregarPropriedades(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header com Logo
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                      ),
                      child: Image.asset('assets/icon.png', width: 50, height: 50),
                    ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                    const SizedBox(height: 16),
                    const Text(
                      'Selecione sua Fazenda',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Lista de Fazendas
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SecaoTituloCustom(titulo: 'Suas Propriedades'),
                      IconButton(
                        onPressed: () => _mostrarOpcoesAdicionar(context),
                        icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (fazendas.isEmpty)
                    _EstadoVazioModerno(theme: theme, onAction: () => _mostrarOpcoesAdicionar(context))
                  else
                    ...fazendas.asMap().entries.map((entry) {
                      return _CardFazendaModerno(
                        fazenda: entry.value,
                        index: entry.key,
                        onTap: () => _selecionarFazenda(context, entry.value, provedor),
                      );
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: fazendas.isNotEmpty
          ? BotaoFlutuanteBovi(
              onPressed: () => _mostrarOpcoesAdicionar(context),
              icone: Icons.add_business_rounded,
              label: 'NOVA FAZENDA',
            )
          : null,
    );
  }

  void _selecionarFazenda(BuildContext context, Propriedade fazenda, ProvedorFazenda provedor) async {
    await provedor.selecionarFazenda(fazenda.id);
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaDashboard()));
    }
  }

  void _mostrarOpcoesAdicionar(BuildContext context) {
    // Reuso do seu modal atual, mas com visual limpo
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Gestão de Dados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _ItemOpcao(
                  icon: Icons.add_business_rounded,
                  titulo: 'Nova Fazenda',
                  cor: Theme.of(ctx).colorScheme.primary,
                  onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const FormDadosFazenda())); },
                ),
                _ItemOpcao(
                  icon: Icons.file_download_outlined,
                  titulo: 'Importar Backup (.bvk)',
                  cor: Colors.orange,
                  onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaRestaurar())); },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecaoTituloCustom extends StatelessWidget {
  final String titulo;
  const _SecaoTituloCustom({required this.titulo});
  @override
  Widget build(BuildContext context) {
    return Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.grey.shade700));
  }
}

class _CardFazendaModerno extends StatelessWidget {
  final Propriedade fazenda;
  final int index;
  final VoidCallback onTap;

  const _CardFazendaModerno({required this.fazenda, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    fazenda.nomeFazenda.isNotEmpty ? fazenda.nomeFazenda[0].toUpperCase() : 'F',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fazenda.nomeFazenda, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('${fazenda.cidade}, ${fazenda.estado}', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                      child: Text(fazenda.sistemaProducao, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05, end: 0),
    );
  }
}

class _EstadoVazioModerno extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onAction;
  const _EstadoVazioModerno({required this.theme, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(IconesApp.fazenda, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Tudo pronto para começar!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Cadastre sua primeira propriedade para gerenciar seu rebanho com inteligência.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          BotaoPadrao(label: 'CRIAR FAZENDA', icone: Icons.add, onPressed: onAction),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ItemOpcao extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final Color cor;
  final VoidCallback onTap;

  const _ItemOpcao({required this.icon, required this.titulo, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: cor),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
