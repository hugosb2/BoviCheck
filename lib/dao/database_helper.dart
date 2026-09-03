import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Helper responsável apenas por abrir, criar e migrar o banco.
/// Extraído de [BancoDadosServico] para que os DAOs tenham SRP.
class DatabaseHelper {
  static final DatabaseHelper instancia = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      try { await db.execute('ALTER TABLE lotes ADD COLUMN capacidade INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute("ALTER TABLE lotes ADD COLUMN descricao TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute("ALTER TABLE animais ADD COLUMN status TEXT DEFAULT 'Ativo'"); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN causaObito TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN paiId TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN maeId TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN dataSaida TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN motivoSaida TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN pesoVendaKg REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE animais ADD COLUMN valorVenda REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE pesagens ADD COLUMN observacao TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE producao_leite ADD COLUMN observacao TEXT'); } catch (_) {}
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE eventos_sanitarios ADD COLUMN dose TEXT'); } catch (_) {}
    }
  }

  Future<void> limparTudo() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'bovicheck.db');
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await deleteDatabase(path);
  }

  /// Para testes com sqflite_common_ffi - permite injetar database em memória
  @visibleForTesting
  void setDatabaseForTest(Database db) {
    _database = db;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
