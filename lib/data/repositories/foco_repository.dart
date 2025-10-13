// lib/data/repositories/foco_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';

class FocoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance; // CORRIGIDO

  Future<FocoDengue> saveFocoCompleto(FocoDengue foco) async {
    final db = await _dbHelper.database;
    
    // Assegura que o foco não está sincronizado ao salvar localmente
    final focoParaSalvar = foco.copyWith(isSynced: false);
    final focoMap = focoParaSalvar.toMap();
    
    return await db.transaction<FocoDengue>((txn) async {
      if (foco.id == null) {
        final id = await txn.insert('focos', focoMap);
        return focoParaSalvar.copyWith(id: id);
      } else {
        await txn.update('focos', focoMap, where: 'id = ?', whereArgs: [foco.id]);
        return focoParaSalvar;
      }
    });
  }

  Future<List<FocoDengue>> getFocosDoBairro(int bairroId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('focos',
        where: 'bairroId = ?',
        whereArgs: [bairroId],
        orderBy: 'dataVisita DESC');
    return List.generate(maps.length, (i) => FocoDengue.fromMap(maps[i]));
  }

  Future<FocoDengue?> getFocoById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('focos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return FocoDengue.fromMap(maps.first);
    }
    return null;
  }
  
  Future<void> deletarFoco(int id) async {
    final db = await _dbHelper.database;
    await db.delete('focos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FocoDengue>> getUnsyncedFocos() async {
    final db = await _dbHelper.database;
    final maps = await db.query('focos', where: 'isSynced = ?', whereArgs: [0]);
    return List.generate(maps.length, (i) => FocoDengue.fromMap(maps[i]));
  }

  Future<void> markFocoAsSynced(String uuid) async {
    final db = await _dbHelper.database;
    await db.update('focos', {'isSynced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
  }
}