import '../modelos/eventos/evento_sanitario.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class EventoSanitarioDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(EventoSanitario evento) async {
    final db = await _helper.database;
    await db.insert(
      'eventos_sanitarios',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> inserirMap(Map<String, dynamic> evento) async {
    final db = await _helper.database;
    await db.insert(
      'eventos_sanitarios',
      evento,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('eventos_sanitarios', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EventoSanitario>> listarPorAnimal(String animalId) async {
    final maps = await listarPorAnimalMap(animalId);
    return maps.map((m) => EventoSanitario.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> listarPorAnimalMap(String animalId) async {
    final db = await _helper.database;
    return await db.query(
      'eventos_sanitarios',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listarPorAnimaisMap(List<String> animalIds) async {
    if (animalIds.isEmpty) return [];
    final db = await _helper.database;
    final ph = List.filled(animalIds.length, '?').join(',');
    return await db.query(
      'eventos_sanitarios',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
  }

  Future<List<EventoSanitario>> listarPorAnimais(List<String> animalIds) async {
    final maps = await listarPorAnimaisMap(animalIds);
    return maps.map((m) => EventoSanitario.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> listarTodasMap() async {
    final db = await _helper.database;
    return await db.query('eventos_sanitarios', orderBy: 'data DESC');
  }
}
