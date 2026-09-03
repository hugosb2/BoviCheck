import 'package:sqflite/sqflite.dart';
import '../modelos/eventos/evento_reprodutivo.dart';
import 'database_helper.dart';

class EventoReprodutivoDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(EventoReprodutivo evento) async {
    final db = await _helper.database;
    await db.insert(
      'eventos_reprodutivos',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('eventos_reprodutivos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EventoReprodutivo>> listarPorAnimal(String animalId) async {
    final db = await _helper.database;
    final res = await db.query(
      'eventos_reprodutivos',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return res.map((x) => EventoReprodutivo.fromMap(x)).toList();
  }

  Future<List<EventoReprodutivo>> listarPorAnimais(List<String> animalIds) async {
    if (animalIds.isEmpty) return [];
    final db = await _helper.database;
    final ph = List.filled(animalIds.length, '?').join(',');
    final res = await db.query(
      'eventos_reprodutivos',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
    return res.map((x) => EventoReprodutivo.fromMap(x)).toList();
  }

  Future<List<EventoReprodutivo>> listarTodas() async {
    final db = await _helper.database;
    final res = await db.query('eventos_reprodutivos', orderBy: 'data DESC');
    return res.map((x) => EventoReprodutivo.fromMap(x)).toList();
  }
}
