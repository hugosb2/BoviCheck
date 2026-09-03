import 'package:sqflite/sqflite.dart';
import '../modelos/propriedade.dart';
import 'database_helper.dart';

class PropriedadeDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(Propriedade p) async {
    final db = await _helper.database;
    await db.insert(
      'propriedades',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizar(Propriedade p) async {
    final db = await _helper.database;
    await db.update(
      'propriedades',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    // Mantém semântica original: deleta manualmente antes da propriedade
    await db.delete('animais', where: 'fazendaId = ?', whereArgs: [id]);
    await db.delete('lotes', where: 'fazendaId = ?', whereArgs: [id]);
    await db.delete('propriedades', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Propriedade>> listarTodas() async {
    final db = await _helper.database;
    final result = await db.query('propriedades');
    return result.map((json) => Propriedade.fromMap(json)).toList();
  }

  Future<Propriedade?> buscarPorId(String id) async {
    final db = await _helper.database;
    final result = await db.query('propriedades', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Propriedade.fromMap(result.first);
  }
}
