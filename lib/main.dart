import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'provedores/provedor_fazenda.dart';
import 'provedores/provedor_tema.dart';
import 'estilos/tema.dart';

import 'telas/2_configuracao_inicial/tela_boas_vindas.dart';
import 'telas/2_configuracao_inicial/tela_selecionar_fazenda.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const BoviCheckApp());
}

class BoviCheckApp extends StatelessWidget {
  const BoviCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProvedorFazenda()),
        ChangeNotifierProvider(create: (_) => ProvedorTema()),
      ],
      child: Consumer<ProvedorTema>(
        builder: (context, provedorTema, _) {
          final isDark = provedorTema.modoTema == ThemeMode.dark ||
              (provedorTema.modoTema == ThemeMode.system &&
                  View.of(context).platformDispatcher.platformBrightness ==
                      Brightness.dark);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: isDark ? Colors.black : Colors.white,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
            child: MaterialApp(
              title: 'BoviCheck',
              debugShowCheckedModeBanner: false,
              theme: TemaApp.criarTemaClaro(provedorTema.corSemente),
              darkTheme: TemaApp.criarTemaEscuro(provedorTema.corSemente),
              themeMode: provedorTema.modoTema,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('pt', 'BR')],
              home: const TelaInicial(),
            ),
          );
        },
      ),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  bool _carregando = true;
  bool _temFazendas = false;

  @override
  void initState() {
    super.initState();
    _verificarFazendas();
  }

  Future<void> _verificarFazendas() async {
    final provedor = context.read<ProvedorFazenda>();
    await provedor.carregarPropriedades();
    if (mounted) {
      setState(() {
        _temFazendas = provedor.propriedades.isNotEmpty;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_temFazendas) {
      return const TelaSelecionarFazenda();
    }

    return const TelaBoasVindas();
  }
}
