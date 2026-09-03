import '../modelos/animal.dart';
import '../modelos/eventos/evento_reprodutivo.dart';
import '../modelos/eventos/pesagem.dart';
import '../modelos/eventos/producao_leite.dart';

/// Classificação qualitativa de cada indicador.
enum StatusIndicador { bom, atencao, ruim, neutro }

/// Calculadora dos índices zootécnicos da fazenda.
///
/// Todos os cálculos respeitam o período [inicio]–[fim] selecionado.
class CalculadoraIndicadores {
  final List<Animal> animais;
  final List<Pesagem> pesagens;
  final List<EventoReprodutivo> reprodutivos;
  final List<ProducaoLeite> leite;
  final DateTime inicio;
  final DateTime fim;

  CalculadoraIndicadores({
    required this.animais,
    required this.pesagens,
    required this.reprodutivos,

    required this.leite,
    required this.inicio,
    required this.fim,
  });

  /// Taxa de natalidade: nascimentos no período / fêmeas aptas (>= 24 meses).
  double get taxaNatalidade {
    final nascimentos = reprodutivos
        .where((e) =>
            e.tipo == 'Parto' && !e.data.isAfter(fim) && !e.data.isBefore(inicio))
        .length;
    final femeasAptas =
        animais.where((a) => a.sexo == 'F' && a.calcularIdadeMeses() >= 24).length;
    if (femeasAptas == 0) return 0.0;
    return (nascimentos / femeasAptas) * 100;
  }

  /// Taxa de prenhez: diagnósticos positivos / diagnósticos no período.
  double get taxaPrenhez {
    final diagnosticos = reprodutivos
        .where((e) =>
            e.tipo.contains('Diagnóstico') &&
            !e.data.isAfter(fim) &&
            !e.data.isBefore(inicio))
        .toList();
    if (diagnosticos.isEmpty) return 0.0;
    final positivos = diagnosticos
        .where((e) =>
            (e.resultado?.toLowerCase().contains('prenhe') ?? false) ||
            (e.resultado?.toLowerCase().contains('positivo') ?? false))
        .length;
    return (positivos / diagnosticos.length) * 100;
  }

  /// Intervalo médio entre partos (IEP), em meses, para as vacas com
  /// pelo menos 2 partos registrados.
  double get iepMeses {
    Map<String, List<DateTime>> partosPorVaca = {};
    for (var evento in reprodutivos) {
      if (evento.tipo == 'Parto') {
        partosPorVaca.putIfAbsent(evento.animalId, () => []).add(evento.data);
      }
    }
    List<int> intervalosDias = [];
    partosPorVaca.forEach((id, datas) {
      if (datas.length >= 2) {
        datas.sort();
        for (int i = 0; i < datas.length - 1; i++) {
          final partoAtual = datas[i + 1];
          if (!partoAtual.isAfter(fim) && !partoAtual.isBefore(inicio)) {
            final diff = partoAtual.difference(datas[i]).inDays;
            if (diff > 250) intervalosDias.add(diff);
          }
        }
      }
    });
    if (intervalosDias.isEmpty) return 0.0;
    return (intervalosDias.reduce((a, b) => a + b) / intervalosDias.length) /
        30.44;
  }

  /// Idade média ao primeiro parto, em meses, para fêmeas com parto no período.
  double get idadePrimeiroPartoMeses {
    List<double> idadesMeses = [];
    for (var animal in animais.where((a) => a.sexo == 'F')) {
      final partos = reprodutivos
          .where((e) => e.animalId == animal.id && e.tipo == 'Parto')
          .toList()
        ..sort((a, b) => a.data.compareTo(b.data));
      if (partos.isNotEmpty) {
        final primeiroParto = partos.first;
        if (!primeiroParto.data.isAfter(fim) && !primeiroParto.data.isBefore(inicio)) {
          final idadeDias =
              primeiroParto.data.difference(animal.dataNascimento).inDays;
          if (idadeDias > 500) idadesMeses.add(idadeDias / 30.44);
        }
      }
    }
    if (idadesMeses.isEmpty) return 0.0;
    return idadesMeses.reduce((a, b) => a + b) / idadesMeses.length;
  }

  /// Ganho médio diário (kg/dia) entre a primeira e a última pesagem de cada
  /// animal cuja última pesagem está no período.
  double get gmdNascDesmame {
    Map<String, List<Pesagem>> porAnimal = {};
    for (var p in pesagens) {
      porAnimal.putIfAbsent(p.animalId, () => []).add(p);
    }
    List<double> gmds = [];
    for (var lista in porAnimal.values) {
      if (lista.length < 2) continue;
      lista.sort((a, b) => a.data.compareTo(b.data));
      final ultima = lista.last;
      if (ultima.data.isAfter(fim) || ultima.data.isBefore(inicio)) continue;
      final primeira = lista.first;
      final dias = ultima.data.difference(primeira.data).inDays;
      if (dias < 7) continue;
      final ganho = ultima.pesoKg - primeira.pesoKg;
      gmds.add(ganho / dias);
    }
    if (gmds.isEmpty) return 0.0;
    return gmds.reduce((a, b) => a + b) / gmds.length;
  }

  /// Taxa de desmame: bezerros desmamados / bezerros nascidos no período.
  ///
  /// Quando o parto não registra o vínculo com o bezerro (`progenieId`),
  /// usa a proporção de desmames sobre nascimentos no período como proxy.
  double get taxaDesmame {
    final partosPeriodo = reprodutivos.where((e) =>
        e.tipo == 'Parto' && !e.data.isAfter(fim) && !e.data.isBefore(inicio));
    if (partosPeriodo.isEmpty) return 0.0;

    final idsNascidos = <String>{};
    for (final e in partosPeriodo) {
      if (e.progenieId != null && e.progenieId!.isNotEmpty) {
        idsNascidos.add(e.progenieId!);
      }
    }

    if (idsNascidos.isEmpty) {
      final desmames = reprodutivos
          .where((e) =>
              e.tipo == 'Desmame' &&
              !e.data.isAfter(fim) &&
              !e.data.isBefore(inicio))
          .length;
      final taxa = (desmames / partosPeriodo.length) * 100;
      return taxa > 100 ? 100.0 : taxa;
    }

    final idsDesmamados = reprodutivos
        .where((e) => e.tipo == 'Desmame')
        .map((e) => e.animalId)
        .toSet();
    final desmamados =
        idsNascidos.where((id) => idsDesmamados.contains(id)).length;
    return (desmamados / idsNascidos.length) * 100;
  }

  /// Taxa de mortalidade: óbitos no período / total de animais cadastrados.
  double get taxaMortalidade {
    final obitos = animais
        .where((a) =>
            !a.isAtivo &&
            a.dataObito != null &&
            !a.dataObito!.isAfter(fim) &&
            !a.dataObito!.isBefore(inicio))
        .length;
    final total = animais.length;
    if (total == 0) return 0.0;
    return (obitos / total) * 100;
  }

  /// Média de leite por vaca por dia (L/dia) no período.
  double get mediaLeiteDia {
    final registros = leite
        .where((l) => !l.data.isAfter(fim) && !l.data.isBefore(inicio))
        .toList();
    if (registros.isEmpty) return 0.0;
    Map<String, double> litrosPorVacaDia = {};
    for (var r in registros) {
      final chaveDia =
          '${r.animalId}_${r.data.toIso8601String().substring(0, 10)}';
      litrosPorVacaDia[chaveDia] =
          (litrosPorVacaDia[chaveDia] ?? 0.0) + r.litros;
    }
    final totalLitros =
        litrosPorVacaDia.values.fold(0.0, (sum, v) => sum + v);
    return totalLitros / litrosPorVacaDia.length;
  }

  StatusIndicador getStatusNatalidade() => taxaNatalidade <= 0
      ? StatusIndicador.neutro
      : (taxaNatalidade >= 80 ? StatusIndicador.bom : (taxaNatalidade >= 60 ? StatusIndicador.atencao : StatusIndicador.ruim));
  StatusIndicador getStatusPrenhez() => taxaPrenhez <= 0
      ? StatusIndicador.neutro
      : (taxaPrenhez >= 85 ? StatusIndicador.bom : (taxaPrenhez >= 70 ? StatusIndicador.atencao : StatusIndicador.ruim));
  StatusIndicador getStatusIEP() => iepMeses <= 0
      ? StatusIndicador.neutro
      : (iepMeses <= 14 ? StatusIndicador.bom : (iepMeses <= 16 ? StatusIndicador.atencao : StatusIndicador.ruim));
  StatusIndicador getStatusIdadeParto() => idadePrimeiroPartoMeses <= 0
      ? StatusIndicador.neutro
      : (idadePrimeiroPartoMeses <= 30 ? StatusIndicador.bom : (idadePrimeiroPartoMeses <= 36 ? StatusIndicador.atencao : StatusIndicador.ruim));
  StatusIndicador getStatusGMD() => gmdNascDesmame <= 0
      ? StatusIndicador.neutro
      : (gmdNascDesmame >= 0.700 ? StatusIndicador.bom : (gmdNascDesmame >= 0.500 ? StatusIndicador.atencao : StatusIndicador.ruim));
  StatusIndicador getStatusDesmame() => taxaDesmame <= 0
      ? StatusIndicador.neutro
      : (taxaDesmame >= 85 ? StatusIndicador.bom : (taxaDesmame >= 50 ? StatusIndicador.atencao : StatusIndicador.ruim));
  StatusIndicador getStatusMortalidade() => taxaMortalidade <= 3
      ? StatusIndicador.bom
      : (taxaMortalidade <= 5 ? StatusIndicador.atencao : StatusIndicador.ruim);
}
