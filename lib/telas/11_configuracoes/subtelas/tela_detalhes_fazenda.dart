import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../estilos/icones.dart';
import '../../../estilos/tema.dart';
import '../../../modelos/propriedade.dart';
import '../../../provedores/provedor_fazenda.dart';
import '../../../servicos/banco_dados_servico.dart';

import '../../2_configuracao_inicial/form_dados_fazenda.dart';

class TelaDetalhesFazenda extends StatefulWidget {
  const TelaDetalhesFazenda({super.key});

  @override
  State<TelaDetalhesFazenda> createState() => _TelaDetalhesFazendaState();
}

class _TelaDetalhesFazendaState extends State<TelaDetalhesFazenda> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provedor = context.watch<ProvedorFazenda>();
    final fazenda = provedor.propriedadeAtiva;

    if (fazenda == null) {
      return const Scaffold(
          body: Center(child: Text('Nenhuma fazenda selecionada.')));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarPadrao(titulo: 'Dados da Propriedade'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          CartaoPadrao(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SvgPicture.asset(
                    IconesApp.iconPropriedadeSvg,
                    width: 40,
                    height: 40,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fazenda.nomeFazenda,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fazenda.cidade}${fazenda.estado.isNotEmpty ? '/${fazenda.estado}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          const SecaoTitulo(texto: 'Informações'),
          const SizedBox(height: 8),
          CartaoPadrao(
            child: Column(
              children: [
                _LinhaInfo(
                  rotulo: 'Proprietário',
                  valor: fazenda.nomeProprietario,
                  icone: Icons.person_outline,
                ),
                const Divider(height: 1),
                _LinhaInfo(
                  rotulo: 'Sistema de Produção',
                  valor: fazenda.sistemaProducao,
                  icone: IconesApp.piquete,
                ),
                const Divider(height: 1),
                _LinhaInfo(
                  rotulo: 'Área Total',
                  valor: '${fazenda.areaTotalHectares.toString().replaceAll('.', ',')} ha',
                  icone: Icons.straighten,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          const SecaoTitulo(texto: 'Localização'),
          const SizedBox(height: 8),
          CartaoPadrao(
            child: Column(
              children: [
                _LinhaInfo(
                  rotulo: 'CEP',
                  valor: fazenda.cep?.isNotEmpty == true ? fazenda.cep! : 'Não informado',
                  icone: Icons.mail_outline,
                ),
                const Divider(height: 1),
                _LinhaInfo(
                  rotulo: 'Cidade',
                  valor: fazenda.cidade,
                  icone: Icons.location_city,
                ),
                const Divider(height: 1),
                _LinhaInfo(
                  rotulo: 'Estado',
                  valor: fazenda.estado.isNotEmpty ? fazenda.estado : 'Não informado',
                  icone: Icons.map,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          BotaoPadrao(
            label: 'EDITAR DADOS',
            icone: Icons.edit,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormDadosFazenda(propriedadeExistente: fazenda),
                ),
              );
            },
            expandido: true,
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          _botaoDeletar(theme, fazenda).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }

  Widget _botaoDeletar(ThemeData theme, Propriedade fazenda) {
    return Card(
      elevation: 0,
      color: Colors.red.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _confirmarDelecao(fazenda),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DELETAR FAZENDA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remover esta fazenda e todos os dados',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarDelecao(Propriedade fazenda) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar fazenda?'),
        content: Text(
          'Tem certeza que deseja deletar "${fazenda.nomeFazenda}"? '
          'Todos os dados serão perdidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETAR'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await BancoDadosServico.instancia.deletePropriedade(fazenda.id);

    if (!mounted) return;
    final provedor = context.read<ProvedorFazenda>();
    await provedor.carregarPropriedades();

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${fazenda.nomeFazenda}" deletada')),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final String rotulo;
  final String valor;
  final IconData icone;

  const _LinhaInfo({
    required this.rotulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: [
          Icon(icone, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
