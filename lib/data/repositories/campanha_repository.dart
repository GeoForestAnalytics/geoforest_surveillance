// Arquivo: lib\data\repositories\campanha_repository.dart
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:sqflite/sqflite.dart';

class CampanhaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertCampanha(Campanha c) async {
    final db = await _dbHelper.database;
    return await db.insert('campanhas', c.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  Future<int> updateCampanha(Campanha c) async {
    final db = await _dbHelper.database;
    return await db.update('campanhas', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<List<Campanha>> getTodasCampanhas(String licenseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'campanhas',
      where: 'licenseId = ?',
      whereArgs: [licenseId],
      orderBy: 'dataCriacao DESC',
    );
    return List.generate(maps.length, (i) => Campanha.fromMap(maps[i]));
  }
  
  Future<void> deleteCampanha(int id) async {
    final db = await _dbHelper.database;
    // Graças ao "ON DELETE CASCADE", apagar uma campanha
    // apagará automaticamente todas as ações, municípios, bairros e focos relacionados.
    await db.delete('campanhas', where: 'id = ?', whereArgs: [id]);
  }
}