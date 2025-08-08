// Arquivo: lib\data\repositories\municipio_repository.dart
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/municipio_model.dart';

class MunicipioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insertMunicipio(Municipio m) async {
    final db = await _dbHelper.database;
    await db.insert('municipios', m.toMap());
  }
  
  Future<List<Municipio>> getMunicipiosDaAcao(int acaoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('municipios', where: 'acaoId = ?', whereArgs: [acaoId]);
    return List.generate(maps.length, (i) => Municipio.fromMap(maps[i]));
  }
  
  // ... outros métodos de update e delete ...
}