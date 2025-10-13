// lib/data/repositories/foco_repository.dart
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';

class FocoRepository {
  // <<< CORREÇÃO APLICADA AQUI >>>
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<FocoDengue> salvarFoco(FocoDengue foco) async {
    final db = await _dbHelper.database;
    final focoMap = foco.toMap();
    
    if (foco.id == null) {
      final id = await db.insert('focos', focoMap);
      final novoFocoMap = (await db.query('focos', where: 'id = ?', whereArgs: [id])).first;
      return FocoDengue.fromMap(novoFocoMap);
    } else {
      await db.update('focos', focoMap, where: 'id = ?', whereArgs: [foco.id]);
      return foco;
    }
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

  // Métodos para sincronização
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