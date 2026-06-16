import 'package:uuid/uuid.dart';
import 'piquete.dart';
import 'animal.dart';

class Propriedade {
  final String id;
  final String nomeProprietario;
  final String nomeFazenda;
  final String? cep;
  final String cidade;
  final String estado;
  final double? gpsLat;
  final double? gpsLong;
  final String sistemaProducao;
  final double areaTotalHectares;
  final double areaProducaoHectares;
  final double areaUtilizadaHectares;

  Propriedade({
    String? id,
    required this.nomeFazenda,
    required this.nomeProprietario,
    required this.cidade,
    required this.estado,
    required this.sistemaProducao,
    this.cep,
    this.gpsLat,
    this.gpsLong,
    this.areaTotalHectares = 0.0,
    this.areaProducaoHectares = 0.0,
    this.areaUtilizadaHectares = 0.0,
  }) : id = id ?? const Uuid().v4();

  // --- Métodos do Diagrama de Classes ---

  List<Piquete> adicionarPiquete(List<Piquete> piquetes, Piquete piquete) {
    return [...piquetes, piquete];
  }

  /// Gera um sumário textual do relatório geral .
  String gerarRelatorioGeral(List<Animal> animais, List<Piquete> piquetes) {
    final total = getTotalAnimais(animais);
    final natal = calcularNatalidadeGlobal(animais);
    final mort = calcularMortalidadeGlobal(animais);
    return '''
Relatório Geral - $nomeFazenda
Proprietário: $nomeProprietario
Total de Animais: $total
Piquetes: ${piquetes.length}
Natalidade Global: ${natal.toStringAsFixed(1)}%
Mortalidade Global: ${mort.toStringAsFixed(1)}%
    '''
        .trim();
  }

  /// Retorna o total de animais ativos.
  int getTotalAnimais(List<Animal> animais) {
    return animais.where((a) => a.isAtivo).length;
  }

  /// Calcula a taxa de natalidade global (% de bezerros sobre fêmeas ativas).
  double calcularNatalidadeGlobal(List<Animal> animais) {
    final femeas = animais.where((a) => a.sexo == 'F' && a.isAtivo).length;
    if (femeas == 0) return 0.0;
    final bezerros = animais
        .where(
          (a) =>
              a.isAtivo &&
              (a.categoria.toLowerCase() == 'bezerro' ||
                  a.categoria.toLowerCase() == 'bezerra'),
        )
        .length;
    return (bezerros / femeas) * 100;
  }

  /// Calcula a taxa de mortalidade global (% animais mortos sobre o total).
  double calcularMortalidadeGlobal(List<Animal> animais) {
    if (animais.isEmpty) return 0.0;
    final mortos = animais.where((a) => a.status == 'Morto').length;
    return (mortos / animais.length) * 100;
  }

  /// Retorna alertas sanitários básicos com base na composição do rebanho.
  List<String> getAlertasSanitarios(List<Animal> animais) {
    final alertas = <String>[];
    final mortalidade = calcularMortalidadeGlobal(animais);
    if (mortalidade > 5.0) {
      alertas.add('⚠️ Alta mortalidade: ${mortalidade.toStringAsFixed(1)}%');
    }
    final bezerros = animais
        .where(
          (a) =>
              a.isAtivo &&
              (a.categoria.toLowerCase() == 'bezerro' ||
                  a.categoria.toLowerCase() == 'bezerra'),
        )
        .length;
    if (bezerros > 0) {
      alertas.add('💉 Verifique vacinação dos $bezerros bezerros(as).');
    }
    if (alertas.isEmpty) {
      alertas.add('✅ Nenhum alerta sanitário crítico identificado.');
    }
    return alertas;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeFazenda': nomeFazenda,
      'nomeProprietario': nomeProprietario,
      'cep': cep,
      'cidade': cidade,
      'estado': estado,
      'gpsLat': gpsLat,
      'gpsLong': gpsLong,
      'sistemaProducao': sistemaProducao,
      'areaTotalHectares': areaTotalHectares,
      'areaProducaoHectares': areaProducaoHectares,
      'areaUtilizadaHectares': areaUtilizadaHectares,
    };
  }

  factory Propriedade.fromMap(Map<String, dynamic> map) {
    return Propriedade(
      id: map['id'],
      nomeFazenda: map['nomeFazenda'] ?? '',
      nomeProprietario: map['nomeProprietario'] ?? '',
      cep: map['cep'],
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      sistemaProducao: map['sistemaProducao'] ?? 'Extensivo',
      gpsLat: map['gpsLat'],
      gpsLong: map['gpsLong'],
      areaTotalHectares: (map['areaTotalHectares'] as num?)?.toDouble() ?? 0.0,
      areaProducaoHectares:
          (map['areaProducaoHectares'] as num?)?.toDouble() ?? 0.0,
      areaUtilizadaHectares:
          (map['areaUtilizadaHectares'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
