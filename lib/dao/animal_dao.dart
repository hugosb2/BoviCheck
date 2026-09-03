import 'package:sqflite/sqflite.dart';
import '../modelos/animal.dart';
import 'database_helper.dart';

class AnimalDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(Animal a) async {
    final db = await _helper.database;
    await db.insert(
      'animais',
      a.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizar(Animal a) async {
    final db = await _helper.database;
    await db.update('animais', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('animais', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Animal>> listarPorFazenda(String fazendaId) async {
    final db = await _helper.database;
    final result = await db.query(
      'animais',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
      orderBy: 'brinco ASC',
    );
    return result.map((json) => Animal.fromMap(json)).toList();
  }

  Future<List<Animal>> listarPorPiquete(String loteId) async {
    final db = await _helper.database;
    final result = await db.query(
      'animais',
      where: 'loteId = ?',
      whereArgs: [loteId],
      orderBy: 'brinco ASC',
    );
    return result.map((json) => Animal.fromMap(json)).toList();
  }

  Future<List<Animal>> listarTodos() async {
    final db = await _helper.database;
    final result = await db.query('animais', orderBy: 'brinco ASC');
    return result.map((json) => Animal.fromMap(json)).toList();
  }

  Future<Animal?> buscarPorId(String id) async {
    final db = await _helper.database;
    final result = await db.query('animais', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Animal.fromMap(result.first);
  }

  Future<int> contarPorFazenda(String fazendaId) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM animais WHERE fazendaId = ?',
      [fazendaId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
