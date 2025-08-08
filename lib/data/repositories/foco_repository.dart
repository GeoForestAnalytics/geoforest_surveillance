// lib/data/repositories/foco_repository.dart
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart'; // Importa o novo modelo

class FocoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Método de salvamento muito mais simples
  Future<FocoDengue> salvarFoco(FocoDengue foco) async {
    final db = await _dbHelper.database;
    final focoMap = foco.toMap();
    
    // Se o foco já tem um ID, atualiza. Senão, insere.
    if (foco.id == null) {
      final id = await db.insert('focos', focoMap);
      return FocoDengue.fromMap( (await db.query('focos', where: 'id = ?', whereArgs: [id])).first );
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
    // ... lógica para buscar um foco por ID ...
  }
  
  Future<void> deletarFoco(int id) async {
    final db = await _dbHelper.database;
    await db.delete('focos', where: 'id = ?', whereArgs: [id]);
  }

  // ... outros métodos de busca e sincronização ...
}