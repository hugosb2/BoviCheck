import 'package:sqflite/sqflite.dart';
import '../modelos/eventos/pesagem.dart';
import 'database_helper.dart';

class PesagemDao {
  final DatabaseHelper _helper = DatabaseHelper.instancia;

  Future<void> inserir(Pesagem pesagem) async {
    final db = await _helper.database;
    await db.insert(
      'pesagens',
      pesagem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Mantém regra original: só atualiza pesoAtual se for a pesagem mais recente
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

  Future<void> deletar(String id) async {
    final db = await _helper.database;
    await db.delete('pesagens', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pesagem>> listarPorAnimal(String animalId) async {
    final db = await _helper.database;
    final res = await db.query(
      'pesagens',
      where: 'animalId = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );
    return res.map((x) => Pesagem.fromMap(x)).toList();
  }

  Future<List<Pesagem>> listarPorAnimais(List<String> animalIds) async {
    if (animalIds.isEmpty) return [];
    final db = await _helper.database;
    final ph = List.filled(animalIds.length, '?').join(',');
    final res = await db.query(
      'pesagens',
      where: 'animalId IN ($ph)',
      whereArgs: animalIds,
      orderBy: 'data DESC',
    );
    return res.map((x) => Pesagem.fromMap(x)).toList();
  }

  Future<List<Pesagem>> listarTodas() async {
    final db = await _helper.database;
    final res = await db.query('pesagens', orderBy: 'data DESC');
    return res.map((x) => Pesagem.fromMap(x)).toList();
  }
}
