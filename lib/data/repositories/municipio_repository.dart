// Arquivo: lib/data/repositories/municipio_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/municipio_model.dart';

class MunicipioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance; // CORRIGIDO

  Future<void> insertMunicipio(Municipio m) async {
    final db = await _dbHelper.database;
    await db.insert('municipios', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMunicipio(Municipio m) async {
    final db = await _dbHelper.database;
    return await db.update('municipios', m.toMap(), where: 'id = ? AND acaoId = ?', whereArgs: [m.id, m.acaoId]);
  }

  Future<List<Municipio>> getMunicipiosDaAcao(int acaoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('municipios', where: 'acaoId = ?', whereArgs: [acaoId], orderBy: 'nome');
    return List.generate(maps.length, (i) => Municipio.fromMap(maps[i]));
  }
  
  Future<void> deleteMunicipio(String id, int acaoId) async {
    final db = await _dbHelper.database;
    await db.delete('municipios', where: 'id = ? AND acaoId = ?', whereArgs: [id, acaoId]);
  }
}