import 'package:uuid/uuid.dart';

class Animal {
  final String id;
  final String fazendaId;
  final String loteId;
  final String brinco;
  final String? nome;
  final String sexo; // 'M' ou 'F'
  final DateTime dataNascimento;
  final String raca;
  final String categoria;
  final double pesoAtualKg;
  final bool isAtivo;
  final String status; // 'Ativo', 'Morto', 'Vendido'
  final DateTime? dataObito;
  final String? causaObito;
  final String? paiId;
  final String? maeId;
  final DateTime? dataSaida;
  final String? motivoSaida;
  final double? pesoVendaKg;
  final double? valorVenda;

  Animal({
    String? id,
    required this.fazendaId,
    required this.loteId,
    required this.brinco,
    this.nome,
    required this.raca,
    required this.sexo,
    required this.categoria,
    required this.dataNascimento,
    required this.pesoAtualKg,
    this.isAtivo = true,
    this.status = 'Ativo',
    this.dataObito,
    this.causaObito,
    this.paiId,
    this.maeId,
    this.dataSaida,
    this.motivoSaida,
    this.pesoVendaKg,
    this.valorVenda,
  }) : id = id ?? const Uuid().v4();

  // --- Métodos do Diagrama de Classes ---

  /// Retorna a idade do animal em meses completos.
  int calcularIdadeMeses() {
    final hoje = DateTime.now();
    int meses = (hoje.year - dataNascimento.year) * 12 +
        (hoje.month - dataNascimento.month);
    if (hoje.day < dataNascimento.day) meses--;
    return meses > 0 ? meses : 0;
  }

  /// Retorna a idade do animal em dias.
  int calcularIdadeDias() {
    return DateTime.now().difference(dataNascimento).inDays;
  }

  /// Calcula o Ganho Médio Diário (GMD) em kg/dia desde o nascimento.
  /// Requer um peso inicial ou usa o pesoAtualKg com base nos dias de vida.
  double calcularGMD() {
    final dias = calcularIdadeDias();
    if (dias <= 0) return 0.0;
    return pesoAtualKg / dias;
  }

  /// Calcula o Intervalo Médio Entre Partos (IEP) em meses para esta fêmea.
  /// Recebe a lista completa de eventos reprodutivos do rebanho e filtra
  /// apenas os partos deste animal. Requer pelo menos 2 partos.
  double calcularIEP(List<dynamic> eventosReprodutivos) {
    if (sexo != 'F') return 0.0;
    final partos =
        eventosReprodutivos
            .where((e) => e.animalId == id && e.tipo == 'Parto')
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    if (partos.length < 2) return 0.0;

    List<int> intervalosDias = [];
    for (int i = 0; i < partos.length - 1; i++) {
      final diff = partos[i + 1].data.difference(partos[i].data).inDays;
      if (diff > 250) intervalosDias.add(diff);
    }
    if (intervalosDias.isEmpty) return 0.0;
    return (intervalosDias.reduce((a, b) => a + b) / intervalosDias.length) /
        30.44;
  }

  /// Calcula a idade do primeiro parto em meses para fêmeas,
  /// baseado nos eventos reprodutivos reais. Retorna 0 se não houver partos.
  double estimarIdadePrimeiroParto(List<dynamic> eventosReprodutivos) {
    if (sexo != 'F') return 0.0;
    final partos =
        eventosReprodutivos
            .where((e) => e.animalId == id && e.tipo == 'Parto')
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    if (partos.isEmpty) return 0.0;

    final idadeDias = partos.first.data.difference(dataNascimento).inDays;
    if (idadeDias <= 0) return 0.0;
    return idadeDias / 30.44;
  }

  /// Registra o óbito do animal, retornando uma cópia atualizada.
  Animal registrarObito(DateTime data, String causa) {
    return Animal(
      id: id,
      fazendaId: fazendaId,
      loteId: loteId,
      brinco: brinco,
      nome: nome,
      raca: raca,
      sexo: sexo,
      categoria: categoria,
      dataNascimento: dataNascimento,
      pesoAtualKg: pesoAtualKg,
      isAtivo: false,
      status: 'Morto',
      dataObito: data,
      causaObito: causa,
      paiId: paiId,
      maeId: maeId,
    );
  }

  /// Retorna o status reprodutivo textual do animal.
  String getStatusReprodutivo() {
    if (sexo == 'M') return 'Reprodutor';
    switch (categoria.toLowerCase()) {
      case 'vaca':
        return 'Vaca em produção';
      case 'novilha':
        return 'Novilha';
      case 'bezerra':
        return 'Bezerra';
      default:
        return 'Não reprodutivo';
    }
  }

  /// Retorna o peso atual do animal (último registrado).
  double getUltimoPeso() => pesoAtualKg;

  /// Retorna a última produção de leite registrada (em litros).
  /// Recebe a lista de registros de produção e filtra pelo animal.
  double getUltimaProducao(List<dynamic> producoes) {
    if (producoes.isEmpty) return 0.0;
    final minhas = producoes.where((p) => p.animalId == id).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    if (minhas.isEmpty) return 0.0;
    return minhas.first.litros;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fazendaId': fazendaId,
      'loteId': loteId,
      'brinco': brinco,
      'nome': nome,
      'raca': raca,
      'sexo': sexo,
      'categoria': categoria,
      'dataNascimento': dataNascimento.toIso8601String(),
      'pesoAtualKg': pesoAtualKg,
      'dataObito': dataObito?.toIso8601String(),
      'isAtivo': isAtivo ? 1 : 0,
      'status': status,
      'causaObito': causaObito,
      'paiId': paiId,
      'maeId': maeId,
      'dataSaida': dataSaida?.toIso8601String(),
      'motivoSaida': motivoSaida,
      'pesoVendaKg': pesoVendaKg,
      'valorVenda': valorVenda,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      fazendaId: map['fazendaId'] ?? '',
      loteId: map['loteId'],
      brinco: map['brinco'],
      nome: map['nome'],
      raca: map['raca'],
      sexo: map['sexo'],
      categoria: map['categoria'] ?? 'Indefinido',
      dataNascimento: DateTime.parse(map['dataNascimento']),
      pesoAtualKg: (map['pesoAtualKg'] as num?)?.toDouble() ?? 0.0,
      dataObito: map['dataObito'] != null
          ? DateTime.parse(map['dataObito'])
          : null,
      isAtivo: map['isAtivo'] == 1,
      status: map['status'] ?? 'Ativo',
      causaObito: map['causaObito'],
      paiId: map['paiId'],
      maeId: map['maeId'],
      dataSaida: map['dataSaida'] != null
          ? DateTime.parse(map['dataSaida'])
          : null,
      motivoSaida: map['motivoSaida'],
      pesoVendaKg: (map['pesoVendaKg'] as num?)?.toDouble(),
      valorVenda: (map['valorVenda'] as num?)?.toDouble(),
    );
  }
}
