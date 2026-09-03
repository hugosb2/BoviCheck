import '../modelos/eventos/abate.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AbateDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(Abate abate) async {
    final db = await _helper.database;
    await db.insert(
      'abates',
      abate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> inserirMap(Map<String, dynamic> abate) async {
    final db = await _helper.database;
    await db.insert(
      'abates',
      abate,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('abates', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarPorAnimalMap(String animalId) async {
    final db = await _helper.database;
    return await db.query(
      'abates',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
  }

  Future<List<Abate>> listarPorAnimal(String animalId) async {
    final maps = await listarPorAnimalMap(animalId);
    return maps.map((m) => Abate.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> listarTodasMap() async {
    final db = await _helper.database;
    return await db.query('abates', orderBy: 'data DESC');
  }
}
