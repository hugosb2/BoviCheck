import 'package:sqflite/sqflite.dart';
import '../modelos/piquete.dart';
import 'database_helper.dart';

class PiqueteDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(Piquete p) async {
    final db = await _helper.database;
    await db.insert(
      'lotes',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizar(Piquete p) async {
    final db = await _helper.database;
    await db.update('lotes', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('lotes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Piquete>> listarPorFazenda(String fazendaId) async {
    final db = await _helper.database;
    final result = await db.query(
      'lotes',
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
    );
    return result.map((json) => Piquete.fromMap(json)).toList();
  }

  Future<Piquete?> buscarPorId(String id) async {
    final db = await _helper.database;
    final result = await db.query('lotes', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Piquete.fromMap(result.first);
  }

  Future<List<Piquete>> listarTodos() async {
    final db = await _helper.database;
    final result = await db.query('lotes');
    return result.map((json) => Piquete.fromMap(json)).toList();
  }
}
