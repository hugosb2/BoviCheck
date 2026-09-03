import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../modelos/propriedade.dart';
import '../modelos/piquete.dart';
import '../modelos/animal.dart';
import '../modelos/eventos/pesagem.dart';
import '../modelos/eventos/evento_reprodutivo.dart';
import '../modelos/eventos/producao_leite.dart';
import '../dao/database_helper.dart';
import '../dao/propriedade_dao.dart';
import '../dao/piquete_dao.dart';
import '../dao/animal_dao.dart';
import '../dao/pesagem_dao.dart';
import '../dao/evento_reprodutivo_dao.dart';
import '../dao/producao_leite_dao.dart';
import '../dao/evento_sanitario_dao.dart';
import '../dao/abate_dao.dart';

/// Facade de compatibilidade. Agora delega para [DatabaseHelper] e DAOs.
/// Mantém a API antiga para não quebrar `provedor_fazenda.dart` e `telas/*`.
class BancoDadosServico {
  static final BancoDadosServico instancia = BancoDadosServico._init();

  BancoDadosServico._init();

  // DAOs internos (SRP)
  final PropriedadeDao _propriedadeDao = PropriedadeDao();
  final PiqueteDao _piqueteDao = PiqueteDao();
  final AnimalDao _animalDao = AnimalDao();
  final PesagemDao _pesagemDao = PesagemDao();
  final EventoReprodutivoDao _reprodutivoDao = EventoReprodutivoDao();
  final ProducaoLeiteDao _leiteDao = ProducaoLeiteDao();
  final EventoSanitarioDao _sanitarioDao = EventoSanitarioDao();
  final AbateDao _abateDao = AbateDao();

  // Proxy para DatabaseHelper (para export/import e acesso direto)
  Future<Database> get database => DatabaseHelper.instancia.database;

  // --- Propriedade ---
  Future<void> adicionarPropriedade(Propriedade p) => _propriedadeDao.inserir(p);
  Future<void> updatePropriedade(Propriedade p) => _propriedadeDao.atualizar(p);
  Future<void> deletePropriedade(String id) => _propriedadeDao.deletar(id);
  Future<List<Propriedade>> getPropriedades() => _propriedadeDao.listarTodas();

  // --- Piquete (lotes) ---
  Future<void> adicionarPiquete(Piquete p) => _piqueteDao.inserir(p);
  Future<void> updatePiquete(Piquete p) => _piqueteDao.atualizar(p);
  Future<void> deletePiquete(String id) => _piqueteDao.deletar(id);
  Future<List<Piquete>> getPiquetesPorFazenda(String fazendaId) =>
      _piqueteDao.listarPorFazenda(fazendaId);

  // --- Animal ---
  Future<void> adicionarAnimal(Animal a) => _animalDao.inserir(a);
  Future<void> updateAnimal(Animal a) => _animalDao.atualizar(a);
  Future<void> deleteAnimal(String id) => _animalDao.deletar(id);
  Future<List<Animal>> getAnimaisPorFazenda(String fazendaId) =>
      _animalDao.listarPorFazenda(fazendaId);

  // --- Pesagem ---
  Future<void> salvarPesagem(Pesagem pesagem) => _pesagemDao.inserir(pesagem);
  Future<List<Pesagem>> getPesagensPorAnimal(String animalId) =>
      _pesagemDao.listarPorAnimal(animalId);
  Future<List<Pesagem>> getPesagensPorAnimais(List<String> animalIds) =>
      _pesagemDao.listarPorAnimais(animalIds);
  Future<void> deletePesagem(String id) => _pesagemDao.deletar(id);

  // --- Reprodutivo ---
  Future<void> salvarEventoReprodutivo(EventoReprodutivo evento) =>
      _reprodutivoDao.inserir(evento);
  Future<List<EventoReprodutivo>> getEventosReprodutivosPorAnimal(String animalId) =>
      _reprodutivoDao.listarPorAnimal(animalId);
  Future<List<EventoReprodutivo>> getEventosReprodutivosPorAnimais(
          List<String> animalIds) =>
      _reprodutivoDao.listarPorAnimais(animalIds);
  Future<void> deleteEventoReprodutivo(String id) => _reprodutivoDao.deletar(id);

  // --- Leite ---
  Future<void> salvarProducaoLeite(ProducaoLeite evento) => _leiteDao.inserir(evento);
  Future<List<ProducaoLeite>> getProducaoLeitePorAnimal(String animalId) =>
      _leiteDao.listarPorAnimal(animalId);
  Future<List<ProducaoLeite>> getProducaoLeitePorAnimais(List<String> animalIds) =>
      _leiteDao.listarPorAnimais(animalIds);
  Future<void> deleteProducaoLeite(String id) => _leiteDao.deletar(id);

  // --- Sanitário (mantém Map para compatibilidade) ---
  Future<void> salvarEventoSanitario(Map<String, dynamic> evento) =>
      _sanitarioDao.inserirMap(evento);
  Future<void> deleteEventoSanitario(String id) => _sanitarioDao.deletar(id);
  Future<List<Map<String, dynamic>>> getEventosSanitariosPorAnimal(
          String animalId) =>
      _sanitarioDao.listarPorAnimalMap(animalId);
  Future<List<Map<String, dynamic>>> getEventosSanitariosPorAnimais(
          List<String> animalIds) =>
      _sanitarioDao.listarPorAnimaisMap(animalIds);

  // --- Abate ---
  Future<void> salvarAbate(Map<String, dynamic> abate) => _abateDao.inserirMap(abate);
  Future<void> deleteAbate(String id) => _abateDao.deletar(id);
  Future<List<Map<String, dynamic>>> getAbatesPorAnimal(String animalId) =>
      _abateDao.listarPorAnimalMap(animalId);

  // --- Utils (export/import/limpar) - permanecem aqui por envolver múltiplas tabelas ---
  Future<void> limparTudo() => DatabaseHelper.instancia.limparTudo();

  Future<String> exportarFazendaJson(String fazendaId) async {
    final db = await database;
    final prop = await db.query(
      'propriedades',
      where: 'id = ?',
      whereArgs: [fazendaId],
    );
    if (prop.isEmpty) throw Exception('Fazenda não encontrada.');
    final lotes = await db.query(
      'lotes',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
    );
    final animais = await db.query(
      'animais',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
    );
    final animalIds = animais.map((a) => a['id'] as String).toList();
    List<Map<String, dynamic>> pesagens = [];
    List<Map<String, dynamic>> eventosReprodutivos = [];
    List<Map<String, dynamic>> producaoLeite = [];
    List<Map<String, dynamic>> eventosSanitarios = [];
    List<Map<String, dynamic>> abates = [];
    if (animalIds.isNotEmpty) {
      final placeholders = List.filled(animalIds.length, '?').join(',');
      pesagens = await db.query(
        'pesagens',
        where: 'animalId IN ($placeholders)',
        whereArgs: animalIds,
      );
      eventosReprodutivos = await db.query(
        'eventos_reprodutivos',
        where: 'animalId IN ($placeholders)',
        whereArgs: animalIds,
      );
      producaoLeite = await db.query(
        'producao_leite',
        where: 'animalId IN ($placeholders)',
        whereArgs: animalIds,
      );
      eventosSanitarios = await db.query(
        'eventos_sanitarios',
        where: 'animalId IN ($placeholders)',
        whereArgs: animalIds,
      );
      abates = await db.query(
        'abates',
        where: 'animalId IN ($placeholders)',
        whereArgs: animalIds,
      );
    }
    final exportData = {
      'tipo': 'fazenda_unica',
      'version': 1,
      'propriedade': prop.first,
      'lotes': lotes,
      'animais': animais,
      'pesagens': pesagens,
      'eventos_reprodutivos': eventosReprodutivos,
      'producao_leite': producaoLeite,
      'eventos_sanitarios': eventosSanitarios,
      'abates': abates,
    };
    return jsonEncode(exportData);
  }

  Future<String> exportarDadosGranular({
    List<String>? fazendaIds,
    List<String>? piqueteIds,
    List<String>? animalIds,
    Set<String>? camposAnimal,
  }) async {
    final db = await database;
    String whereProp = '';
    if (fazendaIds != null && fazendaIds.isNotEmpty) {
      whereProp = 'id IN (${List.filled(fazendaIds.length, '?').join(',')})';
    }
    final prop = await db.query('propriedades',
        where: whereProp.isEmpty ? null : whereProp, whereArgs: fazendaIds);
    String whereLote = '';
    List<String>? argsLote = piqueteIds;
    if (piqueteIds != null && piqueteIds.isNotEmpty) {
      whereLote = 'id IN (${List.filled(piqueteIds.length, '?').join(',')})';
    } else if (fazendaIds != null && fazendaIds.isNotEmpty) {
      whereLote = 'fazendaId IN (${List.filled(fazendaIds.length, '?').join(',')})';
      argsLote = fazendaIds;
    }
    final lotes = await db.query('lotes',
        where: whereLote.isEmpty ? null : whereLote, whereArgs: argsLote);
    String whereAnimal = '';
    List<String>? argsAnimal = animalIds;
    if (animalIds != null && animalIds.isNotEmpty) {
      whereAnimal = 'id IN (${List.filled(animalIds.length, '?').join(',')})';
    } else if (piqueteIds != null && piqueteIds.isNotEmpty) {
      whereAnimal = 'loteId IN (${List.filled(piqueteIds.length, '?').join(',')})';
      argsAnimal = piqueteIds;
    } else if (fazendaIds != null && fazendaIds.isNotEmpty) {
      whereAnimal = 'fazendaId IN (${List.filled(fazendaIds.length, '?').join(',')})';
      argsAnimal = fazendaIds;
    }
    final animaisRaw = await db.query('animais',
        where: whereAnimal.isEmpty ? null : whereAnimal, whereArgs: argsAnimal);
    List<Map<String, dynamic>> animais = animaisRaw;
    if (camposAnimal != null && camposAnimal.isNotEmpty) {
      animais = animaisRaw.map((a) {
        final Map<String, dynamic> filtered = {};
        for (var campo in camposAnimal) {
          if (a.containsKey(campo)) {
            filtered[campo] = a[campo];
          }
        }
        filtered['id'] = a['id'];
        filtered['fazendaId'] = a['fazendaId'];
        filtered['loteId'] = a['loteId'];
        return filtered;
      }).toList();
    }
    final List<String> effectiveAnimalIds =
        animaisRaw.map((a) => a['id'] as String).toList();
    List<Map<String, dynamic>> pesagens = [];
    List<Map<String, dynamic>> eventosReprodutivos = [];
    List<Map<String, dynamic>> producaoLeite = [];
    List<Map<String, dynamic>> eventosSanitarios = [];
    List<Map<String, dynamic>> abates = [];
    if (effectiveAnimalIds.isNotEmpty) {
      final placeholders = List.filled(effectiveAnimalIds.length, '?').join(',');
      pesagens = await db.query('pesagens',
          where: 'animalId IN ($placeholders)', whereArgs: effectiveAnimalIds);
      eventosReprodutivos = await db.query('eventos_reprodutivos',
          where: 'animalId IN ($placeholders)', whereArgs: effectiveAnimalIds);
      producaoLeite = await db.query('producao_leite',
          where: 'animalId IN ($placeholders)', whereArgs: effectiveAnimalIds);
      eventosSanitarios = await db.query('eventos_sanitarios',
          where: 'animalId IN ($placeholders)', whereArgs: effectiveAnimalIds);
      abates = await db.query('abates',
          where: 'animalId IN ($placeholders)', whereArgs: effectiveAnimalIds);
    }
    final exportData = {
      'tipo': 'exportacao_granular',
      'version': 1,
      'propriedades': prop,
      'lotes': lotes,
      'animais': animais,
      'pesagens': pesagens,
      'eventos_reprodutivos': eventosReprodutivos,
      'producao_leite': producaoLeite,
      'eventos_sanitarios': eventosSanitarios,
      'abates': abates,
    };
    return jsonEncode(exportData);
  }

  Future<void> importarFazendaJson(String caminhoNovoArquivo) async {
    final file = File(caminhoNovoArquivo);
    final jsonStr = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final tipo = data['tipo'];
    if (tipo != 'fazenda_unica' && tipo != 'exportacao_granular') {
      throw Exception('Formato de arquivo inválido.');
    }
    final db = await database;
    await db.transaction((txn) async {
      if (tipo == 'fazenda_unica') {
        final prop = data['propriedade'] as Map<String, dynamic>;
        await txn.insert('propriedades', prop,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final props = data['propriedades'] as List;
        for (final p in props) {
          await txn.insert('propriedades', Map<String, dynamic>.from(p),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      final lotes = data['lotes'] as List;
      for (final l in lotes) {
        await txn.insert('lotes', Map<String, dynamic>.from(l),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final animais = data['animais'] as List;
      for (final a in animais) {
        final animalMap = Map<String, dynamic>.from(a);
        animalMap.putIfAbsent('isAtivo', () => 1);
        animalMap.putIfAbsent('status', () => 'Ativo');
        animalMap.putIfAbsent('raca', () => 'Desconhecida');
        animalMap.putIfAbsent('sexo', () => 'M');
        animalMap.putIfAbsent('categoria', () => 'Outro');
        animalMap.putIfAbsent('brinco', () => animalMap['id']);
        animalMap.putIfAbsent('dataNascimento', () => DateTime.now().toIso8601String());
        animalMap.putIfAbsent('pesoAtualKg', () => 0);
        await txn.insert('animais', animalMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final tabelasEventos = {
        'pesagens': 'pesagens',
        'eventos_reprodutivos': 'eventos_reprodutivos',
        'producao_leite': 'producao_leite',
        'eventos_sanitarios': 'eventos_sanitarios',
        'abates': 'abates',
      };
      for (var entry in tabelasEventos.entries) {
        if (data.containsKey(entry.key)) {
          final eventos = data[entry.key] as List;
          for (final e in eventos) {
            await txn.insert(entry.value, Map<String, dynamic>.from(e),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
  }
}
