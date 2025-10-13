import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:sqflite/sqflite.dart';

class AcaoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertAcao(Acao a) async {
    final db = await _dbHelper.database;
    return await db.insert('acoes', a.toMap());
  }

  Future<int> updateAcao(Acao a) async {
    final db = await _dbHelper.database;
    return await db.update('acoes', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<List<Acao>> getAcoesDaCampanha(int campanhaId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('acoes', where: 'campanhaId = ?', whereArgs: [campanhaId]);
    return List.generate(maps.length, (i) => Acao.fromMap(maps[i]));
  }
  
  // <<< ADICIONE ESTE MÉTODO >>>
  /// Retorna uma lista com todas as ações de todas as campanhas.
  Future<List<Acao>> getTodasAcoes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('acoes', orderBy: 'dataCriacao DESC');
    return List.generate(maps.length, (i) => Acao.fromMap(maps[i]));
  }
  // <<< FIM DA ADIÇÃO >>>

  Future<void> deleteAcao(int id) async {
    final db = await _dbHelper.database;
    await db.delete('acoes', where: 'id = ?', whereArgs: [id]);
  }
}