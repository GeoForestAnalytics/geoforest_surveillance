// Arquivo: lib/data/repositories/bairro_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';

class BairroRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance; // CORRIGIDO

  Future<int> insertBairro(Bairro b) async {
    final db = await _dbHelper.database;
    return await db.insert('bairros', b.toMap());
  }

  Future<int> updateBairro(Bairro b) async {
    final db = await _dbHelper.database;
    return await db.update('bairros', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<List<Bairro>> getBairrosDoMunicipio(String municipioId, int acaoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('bairros', where: 'municipioId = ? AND acaoId = ?', whereArgs: [municipioId, acaoId], orderBy: 'nome');
    return List.generate(maps.length, (i) => Bairro.fromMap(maps[i]));
  }

  Future<List<Bairro>> getTodosBairros() async {
    final db = await _dbHelper.database;
    final maps = await db.query('bairros', orderBy: 'nome');
    return List.generate(maps.length, (i) => Bairro.fromMap(maps[i]));
  }

  Future<void> deleteBairro(int id) async {
    final db = await _dbHelper.database;
    await db.delete('bairros', where: 'id = ?', whereArgs: [id]);
  }
}