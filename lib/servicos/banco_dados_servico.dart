import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../modelos/propriedade.dart';
import '../modelos/piquete.dart';
import '../modelos/animal.dart';
import '../modelos/eventos/pesagem.dart';
import '../modelos/eventos/evento_reprodutivo.dart';
import '../modelos/eventos/producao_leite.dart';

class BancoDadosServico {
  static final BancoDadosServico instancia = BancoDadosServico._init();
  static Database? _database;

  BancoDadosServico._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bovicheck.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 5,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Propriedades
    await db.execute('''
      CREATE TABLE IF NOT EXISTS propriedades (
        id TEXT PRIMARY KEY,
        nomeFazenda TEXT NOT NULL,
        nomeProprietario TEXT NOT NULL,
        cep TEXT,
        cidade TEXT NOT NULL,
        estado TEXT NOT NULL,
        gpsLat REAL,
        gpsLong REAL,
        sistemaProducao TEXT NOT NULL,
        areaTotalHectares REAL NOT NULL,
        areaProducaoHectares REAL DEFAULT 0,
        areaUtilizadaHectares REAL DEFAULT 0
      )
    ''');

    // 2. Lotes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lotes (
        id TEXT PRIMARY KEY,
        fazendaId TEXT NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        capacidade INTEGER NOT NULL DEFAULT 0,
        descricao TEXT NOT NULL DEFAULT '',
        sistemaProducao TEXT NOT NULL DEFAULT 'Extensivo',
        areaHectares REAL DEFAULT 0,
        FOREIGN KEY (fazendaId) REFERENCES propriedades (id) ON DELETE CASCADE
      )
    ''');

    // 3. Animais
    await db.execute('''
      CREATE TABLE IF NOT EXISTS animais (
        id TEXT PRIMARY KEY,
        fazendaId TEXT NOT NULL,
        loteId TEXT NOT NULL,
        brinco TEXT NOT NULL,
        nome TEXT,
        raca TEXT NOT NULL,
        sexo TEXT NOT NULL,
        categoria TEXT NOT NULL,
        dataNascimento TEXT NOT NULL,
        pesoAtualKg REAL NOT NULL,
        dataObito TEXT,
        isAtivo INTEGER NOT NULL,
        status TEXT DEFAULT 'Ativo',
        causaObito TEXT,
        paiId TEXT,
        maeId TEXT,
        dataSaida TEXT,
        motivoSaida TEXT,
        pesoVendaKg REAL,
        valorVenda REAL,
        FOREIGN KEY (fazendaId) REFERENCES propriedades (id) ON DELETE CASCADE,
        FOREIGN KEY (loteId) REFERENCES lotes (id) ON DELETE NO ACTION
      )
    ''');

    // 4. Pesagens
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pesagens (
        id TEXT PRIMARY KEY,
        animalId TEXT NOT NULL,
        data TEXT NOT NULL,
        pesoKg REAL NOT NULL,
        etapa TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (animalId) REFERENCES animais (id) ON DELETE CASCADE
      )
    ''');

    // 5. Eventos Reprodutivos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS eventos_reprodutivos (
        id TEXT PRIMARY KEY,
        animalId TEXT NOT NULL,
        data TEXT NOT NULL,
        tipo TEXT NOT NULL,
        resultado TEXT,
        observacao TEXT,
        progenieId TEXT,
        dataPrevistaParto TEXT,
        isPrimeiroParto INTEGER DEFAULT 0,
        FOREIGN KEY (animalId) REFERENCES animais (id) ON DELETE CASCADE
      )
    ''');

    // 6. Produção de Leite
    await db.execute('''
      CREATE TABLE IF NOT EXISTS producao_leite (
        id TEXT PRIMARY KEY,
        animalId TEXT NOT NULL,
        data TEXT NOT NULL,
        litros REAL NOT NULL,
        periodo TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (animalId) REFERENCES animais (id) ON DELETE CASCADE
      )
    ''');

    // 7. Eventos Sanitários
    await db.execute('''
      CREATE TABLE IF NOT EXISTS eventos_sanitarios (
        id TEXT PRIMARY KEY,
        animalId TEXT NOT NULL,
        data TEXT NOT NULL,
        tipo TEXT NOT NULL,
        nomeMedicamento TEXT,
        dose TEXT,
        observacao TEXT,
        FOREIGN KEY (animalId) REFERENCES animais (id) ON DELETE CASCADE
      )
    ''');

    // 8. Abates
    await db.execute('''
      CREATE TABLE IF NOT EXISTS abates (
        id TEXT PRIMARY KEY,
        animalId TEXT NOT NULL,
        data TEXT NOT NULL,
        pesoVivoKg REAL NOT NULL,
        pesoCarcacaKg REAL NOT NULL,
        observacao TEXT,
        FOREIGN KEY (animalId) REFERENCES animais (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE propriedades ADD COLUMN cep TEXT');
      await db.execute(
        'ALTER TABLE propriedades ADD COLUMN areaProducaoHectares REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE propriedades ADD COLUMN areaUtilizadaHectares REAL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      // Tenta adicionar colunas sistemaProducao e areaHectares (pode já existir se o onCreate mudou)
      try {
        await db.execute(
          "ALTER TABLE lotes ADD COLUMN sistemaProducao TEXT NOT NULL DEFAULT 'Extensivo'",
        );
        await db.execute(
          'ALTER TABLE lotes ADD COLUMN areaHectares REAL DEFAULT 0',
        );
      } catch (e) {
        debugPrint('Colunas sistemaProducao/areaHectares já existem ou erro: $e');
      }
    }
    if (oldVersion < 4) {
      // 1. Novas colunas para Lotes (caso tenham sido esquecidas em versões anteriores do código)
      try { await db.execute('ALTER TABLE lotes ADD COLUMN capacidade INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute("ALTER TABLE lotes ADD COLUMN descricao TEXT NOT NULL DEFAULT ''"); } catch (_) {}

      // 2. Novas colunas para Animais
      try { await db.execute("ALTER TABLE animais ADD COLUMN status TEXT DEFAULT 'Ativo'"); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN causaObito TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN paiId TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN maeId TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN dataSaida TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN motivoSaida TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN pesoVendaKg REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN valorVenda REAL'); } catch (_) {}

      // 3. Novas colunas para Pesagens e Leite
      try { await db.execute('ALTER TABLE pesagens ADD COLUMN observacao TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE producao_leite ADD COLUMN observacao TEXT'); } catch (_) {}
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE eventos_sanitarios ADD COLUMN dose TEXT'); } catch (_) {}
    }
  }

  // --- CRUD GERAL ---

  Future<void> adicionarPropriedade(Propriedade p) async {
    final db = await database;
    await db.insert(
      'propriedades',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePropriedade(Propriedade p) async {
    final db = await database;
    await db.update(
      'propriedades',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> deletePropriedade(String id) async {
    final db = await database;
    await db.delete('animais', where: 'fazendaId = ?', whereArgs: [id]);
    await db.delete('lotes', where: 'fazendaId = ?', whereArgs: [id]);
    await db.delete('propriedades', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Propriedade>> getPropriedades() async {
    final db = await database;
    final result = await db.query('propriedades');
    return result.map((json) => Propriedade.fromMap(json)).toList();
  }

  Future<void> adicionarPiquete(Piquete p) async {
    final db = await database;
    await db.insert(
      'lotes',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePiquete(Piquete p) async {
    final db = await database;
    await db.update('lotes', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<List<Piquete>> getPiquetesPorFazenda(String fazendaId) async {
    final db = await database;
    final result = await db.query(
      'lotes',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
    );
    return result.map((json) => Piquete.fromMap(json)).toList();
  }

  Future<void> adicionarAnimal(Animal a) async {
    final db = await database;
    await db.insert(
      'animais',
      a.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAnimal(Animal a) async {
    final db = await database;
    await db.update('animais', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<List<Animal>> getAnimaisPorFazenda(String fazendaId) async {
    final db = await database;
    final result = await db.query(
      'animais',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
      orderBy: 'brinco ASC',
    );
    return result.map((json) => Animal.fromMap(json)).toList();
  }

  // --- Eventos ---

  Future<void> salvarPesagem(Pesagem pesagem) async {
    final db = await database;
    await db.insert(
      'pesagens',
      pesagem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Só atualiza o peso atual se esta pesagem for a mais recente do animal,
    // para não sobrescrever o peso atual com uma pesagem histórica.
    final maisRecente = await db.query(
      'pesagens',
      columns: ['data', 'pesoKg'],
      where: 'animalId = ?',
      whereArgs: [pesagem.animalId],
      orderBy: 'data DESC',
      limit: 1,
    );
    if (maisRecente.isNotEmpty) {
      final dataMaisRecente = DateTime.parse(maisRecente.first['data'] as String);
      if (!pesagem.data.isBefore(dataMaisRecente)) {
        await db.update(
          'animais',
          {'pesoAtualKg': pesagem.pesoKg},
          where: 'id = ?',
          whereArgs: [pesagem.animalId],
        );
      }
    }
  }

  Future<List<Pesagem>> getPesagensPorAnimal(String animalId) async {
    final db = await database;
    final res = await db.query(
      'pesagens',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return res.map((x) => Pesagem.fromMap(x)).toList();
  }

  Future<List<Pesagem>> getPesagensPorAnimais(List<String> animalIds) async {
    if (animalIds.isEmpty) return [];
    final db = await database;
    final ph = List.filled(animalIds.length, '?').join(',');
    final res = await db.query(
      'pesagens',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
    return res.map((x) => Pesagem.fromMap(x)).toList();
  }

  Future<void> salvarEventoReprodutivo(EventoReprodutivo evento) async {
    final db = await database;
    await db.insert(
      'eventos_reprodutivos',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EventoReprodutivo>> getEventosReprodutivosPorAnimal(
    String animalId,
  ) async {
    final db = await database;
    final res = await db.query(
      'eventos_reprodutivos',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return res.map((x) => EventoReprodutivo.fromMap(x)).toList();
  }

  Future<List<EventoReprodutivo>> getEventosReprodutivosPorAnimais(
    List<String> animalIds,
  ) async {
    if (animalIds.isEmpty) return [];
    final db = await database;
    final ph = List.filled(animalIds.length, '?').join(',');
    final res = await db.query(
      'eventos_reprodutivos',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
    return res.map((x) => EventoReprodutivo.fromMap(x)).toList();
  }

  Future<void> salvarProducaoLeite(ProducaoLeite evento) async {
    final db = await database;
    await db.insert(
      'producao_leite',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProducaoLeite>> getProducaoLeitePorAnimal(String animalId) async {
    final db = await database;
    final res = await db.query(
      'producao_leite',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return res.map((x) => ProducaoLeite.fromMap(x)).toList();
  }

  Future<List<ProducaoLeite>> getProducaoLeitePorAnimais(
    List<String> animalIds,
  ) async {
    if (animalIds.isEmpty) return [];
    final db = await database;
    final ph = List.filled(animalIds.length, '?').join(',');
    final res = await db.query(
      'producao_leite',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
    return res.map((x) => ProducaoLeite.fromMap(x)).toList();
  }

  Future<void> salvarEventoSanitario(Map<String, dynamic> evento) async {
    final db = await database;
    await db.insert(
      'eventos_sanitarios',
      evento,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> salvarAbate(Map<String, dynamic> abate) async {
    final db = await database;
    await db.insert(
      'abates',
      abate,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getEventosSanitariosPorAnimal(
    String animalId,
  ) async {
    final db = await database;
    return await db.query(
      'eventos_sanitarios',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getEventosSanitariosPorAnimais(
    List<String> animalIds,
  ) async {
    if (animalIds.isEmpty) return [];
    final db = await database;
    final ph = List.filled(animalIds.length, '?').join(',');
    return await db.query(
      'eventos_sanitarios',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAbatesPorAnimal(String animalId) async {
    final db = await database;
    return await db.query(
      'abates',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
  }

  // --- Utils ---

  Future<void> limparTudo() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'bovicheck.db');
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await deleteDatabase(path);
  }

  Future<String> exportarFazendaJson(String fazendaId) async {
    final db = await database;

    // Propriedade
    final prop = await db.query(
      'propriedades',
      where: 'id = ?',
      whereArgs: [fazendaId],
    );
    if (prop.isEmpty) throw Exception('Fazenda não encontrada.');

    // Piquetes
    final lotes = await db.query(
      'lotes',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
    );

    // Animais
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

    // 1. Propriedades
    String whereProp = '';
    if (fazendaIds != null && fazendaIds.isNotEmpty) {
      whereProp = 'id IN (${List.filled(fazendaIds.length, '?').join(',')})';
    }
    final prop = await db.query('propriedades',
        where: whereProp.isEmpty ? null : whereProp, whereArgs: fazendaIds);

    // 2. Piquetes
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

    // 3. Animais
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

    // Filtrar campos do animal se solicitado
    List<Map<String, dynamic>> animais = animaisRaw;
    if (camposAnimal != null && camposAnimal.isNotEmpty) {
      // Sempre manter ID e fazendaId/loteId para integridade se possível, 
      // mas se o usuário quer APENAS alguns campos, filtramos.
      animais = animaisRaw.map((a) {
        final Map<String, dynamic> filtered = {};
        for (var campo in camposAnimal) {
          if (a.containsKey(campo)) {
            filtered[campo] = a[campo];
          }
        }
        // Mantém campos obrigatórios para a integridade do banco
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
      // 1. Importar Propriedades
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

      // 2. Importar Piquetes
      final lotes = data['lotes'] as List;
      for (final l in lotes) {
        await txn.insert('lotes', Map<String, dynamic>.from(l),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 3. Importar Animais
      final animais = data['animais'] as List;
      for (final a in animais) {
        final animalMap = Map<String, dynamic>.from(a);
        // Arquivos gerados por versões antigas podem omitir colunas NOT NULL
        // (ex.: isAtivo). Aplica padrões para não quebrar a importação.
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

      // 4. Importar Eventos (Pesagens, Reprodutivos, Leite, Sanitários, Abates)
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
