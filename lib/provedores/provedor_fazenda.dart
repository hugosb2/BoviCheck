import 'package:flutter/material.dart';
import '../modelos/propriedade.dart';
import '../modelos/piquete.dart';
import '../modelos/animal.dart';
import '../modelos/eventos/evento_reprodutivo.dart';
import '../modelos/eventos/evento_sanitario.dart';
import '../modelos/eventos/pesagem.dart';
import '../modelos/eventos/producao_leite.dart';
import '../servicos/banco_dados_servico.dart';

class ProvedorFazenda extends ChangeNotifier {
  Propriedade? _propriedadeAtiva;
  List<Propriedade> _propriedades = [];
  List<Piquete> _piquetes = [];
  List<Animal> _animais = [];
  List<EventoReprodutivo> _eventosReprodutivos = [];
  List<EventoSanitario> _eventosSanitarios = [];
  List<Pesagem> _pesagens = [];
  List<ProducaoLeite> _producaoLeite = [];
  bool _isLoading = false;

  // Getters Básicos
  Propriedade? get propriedadeAtiva => _propriedadeAtiva;
  List<Propriedade> get propriedades => _propriedades;
  List<Piquete> get piquetes => _piquetes;
  List<Animal> get animais => _animais;
  bool get isLoading => _isLoading;

  // Getters de Dados Completos (Necessários para Indicadores)
  List<Pesagem> get pesagens => _pesagens;
  List<EventoReprodutivo> get eventosReprodutivos => _eventosReprodutivos;
  List<ProducaoLeite> get producaoLeite => _producaoLeite;

  // Getters Calculados (Necessários para Dashboard e IA)
  int get totalAnimais => _animais.length;
  int get totalAnimaisAtivos => _animais.where((a) => a.isAtivo).length;
  int get totalPiquetes => _piquetes.length;

  int get totalAnimaisDoentes {
    final agora = DateTime.now();
    final inicioSemana = agora.subtract(const Duration(days: 7));
    return _animais.where((a) {
      return a.isAtivo &&
          _eventosSanitarios.any(
            (e) =>
                e.animalId == a.id &&
                (e.tipo.toLowerCase().contains('doença') || e.tipo.toLowerCase().contains('tratamento')) &&
                !e.data.isBefore(inicioSemana) &&
                !e.data.isAfter(agora),
          );
    }).length;
  }

  int get totalNascimentos {
    final agora = DateTime.now();
    final inicioAno = DateTime(agora.year, 1, 1);
    return _eventosReprodutivos
        .where((e) => e.tipo == 'Parto' && !e.data.isBefore(inicioAno) && !e.data.isAfter(agora))
        .length;
  }

  double get totalLeiteMes {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    return _producaoLeite
        .where((e) => !e.data.isBefore(inicioMes) && !e.data.isAfter(agora))
        .fold(0.0, (sum, item) => sum + item.litros);
  }

  double get taxaMortalidade {
    if (_animais.isEmpty) return 0.0;
    final obitos = _animais.where((a) => !a.isAtivo && a.dataObito != null).length;
    return (obitos / _animais.length) * 100;
  }

  double get mediaGMD {
    if (_pesagens.isEmpty) return 0.0;
    Map<String, List<Pesagem>> pesagensPorAnimal = {};
    for (var p in _pesagens) {
      if (!pesagensPorAnimal.containsKey(p.animalId)) {
        pesagensPorAnimal[p.animalId] = [];
      }
      pesagensPorAnimal[p.animalId]!.add(p);
    }

    List<double> gmds = [];
    pesagensPorAnimal.forEach((id, lista) {
      if (lista.length >= 2) {
        lista.sort((a, b) => a.data.compareTo(b.data));
        final primeira = lista.first;
        final ultima = lista.last;
        final dias = ultima.data.difference(primeira.data).inDays;
        final ganho = ultima.pesoKg - primeira.pesoKg;
        if (dias >= 7) {
          gmds.add(ganho / dias);
        }
      }
    });

    if (gmds.isEmpty) return 0.0;
    return gmds.reduce((a, b) => a + b) / gmds.length;
  }

  // Carregamento Inicial
  Future<void> carregarPropriedades() async {
    _isLoading = true;
    notifyListeners();
    try {
      _propriedades = await BancoDadosServico.instancia.getPropriedades();

      // Atualiza a propriedade ativa se necessário
      if (_propriedadeAtiva != null) {
        try {
          _propriedadeAtiva = _propriedades.firstWhere(
            (p) => p.id == _propriedadeAtiva!.id,
          );
        } catch (_) {
          _propriedadeAtiva = null; // Foi deletada
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar propriedades: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seleção de Fazenda
  Future<void> selecionarFazenda(dynamic fazendaOrId) async {
    _isLoading = true;
    notifyListeners();

    if (fazendaOrId is Propriedade) {
      _propriedadeAtiva = fazendaOrId;
    } else if (fazendaOrId is String) {
      // Sempre recarrega o cache: após uma edição a lista pode estar obsoleta.
      await carregarPropriedades();
      try {
        _propriedadeAtiva = _propriedades.firstWhere(
          (p) => p.id == fazendaOrId,
        );
      } catch (_) {
        _propriedadeAtiva = null;
      }
    }

    if (_propriedadeAtiva != null) {
      await carregarPiquetes(_propriedadeAtiva!.id);
      await carregarAnimais(_propriedadeAtiva!.id);
    } else {
      _piquetes = [];
      _animais = [];
      _eventosReprodutivos = [];
      _eventosSanitarios = [];
      _pesagens = [];
      _producaoLeite = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- CRUD PROPRIEDADE ---
  Future<void> adicionarPropriedade(Propriedade p) async {
    await BancoDadosServico.instancia.adicionarPropriedade(p);
    await carregarPropriedades();
    await selecionarFazenda(p);
  }

  // --- CRUD PIQUETES ---
  Future<void> carregarPiquetes(String fazendaId) async {
    try {
      _piquetes = await BancoDadosServico.instancia.getPiquetesPorFazenda(fazendaId);
    } catch (e) {
      debugPrint('Erro ao carregar piquetes: $e');
    }
    notifyListeners();
  }

  Future<void> adicionarPiquete(Piquete piquete) async {
    await BancoDadosServico.instancia.adicionarPiquete(piquete);
    if (_propriedadeAtiva != null) {
      await carregarPiquetes(_propriedadeAtiva!.id);
    }
  }

  Future<void> atualizarPiquete(Piquete piquete) async {
    await BancoDadosServico.instancia.updatePiquete(piquete);
    if (_propriedadeAtiva != null) {
      await carregarPiquetes(_propriedadeAtiva!.id);
    }
  }

  Future<void> excluirPiquete(String piqueteId) async {
    await BancoDadosServico.instancia.deletePiquete(piqueteId);
    if (_propriedadeAtiva != null) {
      await carregarPiquetes(_propriedadeAtiva!.id);
    }
  }

  // --- CRUD ANIMAIS ---
  Future<void> carregarAnimais(String fazendaId) async {
    try {
      final db = BancoDadosServico.instancia;
      _animais = await db.getAnimaisPorFazenda(fazendaId);

      final ids = _animais.map((a) => a.id).toList();

      _eventosReprodutivos = await db.getEventosReprodutivosPorAnimais(ids);

      final sanitariosMaps = await db.getEventosSanitariosPorAnimais(ids);
      _eventosSanitarios = sanitariosMaps.map((m) => EventoSanitario.fromMap(m)).toList();

      _pesagens = await db.getPesagensPorAnimais(ids);

      _producaoLeite = await db.getProducaoLeitePorAnimais(ids);
    } catch (e) {
      debugPrint('Erro ao carregar animais/eventos: $e');
    }

    notifyListeners();
  }

  // --- EXCLUSÕES (Eventos, Animais e Piquetes) ---

  Future<void> excluirAnimal(String animalId) async {
    await BancoDadosServico.instancia.deleteAnimal(animalId);
    if (_propriedadeAtiva != null) {
      await carregarAnimais(_propriedadeAtiva!.id);
    }
  }

  Future<void> excluirPesagem(String eventoId) async {
    await BancoDadosServico.instancia.deletePesagem(eventoId);
    if (_propriedadeAtiva != null) {
      await carregarAnimais(_propriedadeAtiva!.id);
    }
  }

  Future<void> excluirEventoReprodutivo(String eventoId) async {
    await BancoDadosServico.instancia.deleteEventoReprodutivo(eventoId);
    if (_propriedadeAtiva != null) {
      await carregarAnimais(_propriedadeAtiva!.id);
    }
  }

  Future<void> excluirProducaoLeite(String eventoId) async {
    await BancoDadosServico.instancia.deleteProducaoLeite(eventoId);
    if (_propriedadeAtiva != null) {
      await carregarAnimais(_propriedadeAtiva!.id);
    }
  }

  Future<void> excluirEventoSanitario(String eventoId) async {
    await BancoDadosServico.instancia.deleteEventoSanitario(eventoId);
    if (_propriedadeAtiva != null) {
      await carregarAnimais(_propriedadeAtiva!.id);
    }
  }

  Future<void> excluirAbate(String eventoId) async {
    await BancoDadosServico.instancia.deleteAbate(eventoId);
    if (_propriedadeAtiva != null) {
      await carregarAnimais(_propriedadeAtiva!.id);
    }
  }

  // Limpeza (Logout)
  void limparEstado() {
    _propriedadeAtiva = null;
    _piquetes = [];
    _animais = [];
    _eventosReprodutivos = [];
    _eventosSanitarios = [];
    _pesagens = [];
    _producaoLeite = [];
    notifyListeners();
  }
}
