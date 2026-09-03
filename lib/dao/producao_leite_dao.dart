import 'package:sqflite/sqflite.dart';
import '../modelos/eventos/producao_leite.dart';
import 'database_helper.dart';

class ProducaoLeiteDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(ProducaoLeite evento) async {
    final db = await _helper.database;
    await db.insert(
      'producao_leite',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('producao_leite', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProducaoLeite>> listarPorAnimal(String animalId) async {
    final db = await _helper.database;
    final res = await db.query(
      'producao_leite',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return res.map((x) => ProducaoLeite.fromMap(x)).toList();
  }

  Future<List<ProducaoLeite>> listarPorAnimais(List<String> animalIds) async {
    if (animalIds.isEmpty) return [];
    final db = await _helper.database;
    final ph = List.filled(animalIds.length, '?').join(',');
    final res = await db.query(
      'producao_leite',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
    return res.map((x) => ProducaoLeite.fromMap(x)).toList();
  }

  Future<List<ProducaoLeite>> listarTodas() async {
    final db = await _helper.database;
    final res = await db.query('producao_leite', orderBy: 'data DESC');
    return res.map((x) => ProducaoLeite.fromMap(x)).toList();
  }
}
