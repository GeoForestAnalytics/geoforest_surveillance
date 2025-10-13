// Arquivo: lib\data\repositories\bairro_repository.dart
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';

class BairroRepository {
  // <<< CORREÇÃO APLICADA AQUI >>>
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertBairro(Bairro b) async {
    final db = await _dbHelper.database;
    return await db.insert('bairros', b.toMap());
  }

  Future<List<Bairro>> getBairrosDoMunicipio(String municipioId, int acaoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('bairros', where: 'municipioId = ? AND acaoId = ?', whereArgs: [municipioId, acaoId]);
    return List.generate(maps.length, (i) => Bairro.fromMap(maps[i]));
  }
  
  // TODO: Implementar os outros métodos de update e delete conforme a necessidade
}