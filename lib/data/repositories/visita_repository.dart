// Arquivo: lib/data/repositories/visita_repository.dart (NOVO ARQUIVO)

import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';

class VisitaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insere uma nova visita no banco de dados.
  Future<int> insertVisita(Visita visita) async {
    final db = await _dbHelper.database;
    return await db.insert('visitas', visita.toMap());
  }

  /// Atualiza os dados de uma visita existente.
  Future<int> updateVisita(Visita visita) async {
    final db = await _dbHelper.database;
    return await db.update(
      'visitas',
      visita.toMap(),
      where: 'id = ?',
      whereArgs: [visita.id],
    );
  }

  /// Busca uma visita específica pelo seu ID local.
  Future<Visita?> getVisitaById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'visitas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Visita.fromMap(maps.first);
    }
    return null;
  }

  /// Retorna uma lista com todas as visitas realizadas em um determinado imóvel.
  Future<List<Visita>> getVisitasDoImovel(int imovelId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'visitas',
      where: 'imovelId = ?',
      whereArgs: [imovelId],
      orderBy: 'dataVisita DESC',
    );
    return List.generate(maps.length, (i) => Visita.fromMap(maps[i]));
  }

  /// Retorna uma lista com todas as visitas de uma campanha.
  Future<List<Visita>> getVisitasDaCampanha(int campanhaId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'visitas',
      where: 'campanhaId = ?',
      whereArgs: [campanhaId],
      orderBy: 'dataVisita DESC',
    );
    return List.generate(maps.length, (i) => Visita.fromMap(maps[i]));
  }

  /// Deleta uma visita do banco de dados local.
  Future<void> deleteVisita(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'visitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}