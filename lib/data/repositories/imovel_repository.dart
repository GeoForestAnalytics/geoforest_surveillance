// Arquivo: lib/data/repositories/imovel_repository.dart (NOVO ARQUIVO)

import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';

class ImovelRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insere um novo imóvel no banco de dados.
  Future<int> insertImovel(Imovel imovel) async {
    final db = await _dbHelper.database;
    return await db.insert('imoveis', imovel.toMap());
  }

  /// Atualiza os dados de um imóvel existente.
  Future<int> updateImovel(Imovel imovel) async {
    final db = await _dbHelper.database;
    return await db.update(
      'imoveis',
      imovel.toMap(),
      where: 'id = ?',
      whereArgs: [imovel.id],
    );
  }

  /// Busca um imóvel específico pelo seu ID local.
  Future<Imovel?> getImovelById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'imoveis',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Imovel.fromMap(maps.first);
    }
    return null;
  }

  /// Retorna uma lista com todos os imóveis cadastrados em um determinado bairro.
  Future<List<Imovel>> getImoveisDoBairro(int bairroId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'imoveis',
      where: 'bairroId = ?',
      whereArgs: [bairroId],
      orderBy: 'logradouro, numero',
    );
    return List.generate(maps.length, (i) => Imovel.fromMap(maps[i]));
  }

  /// Retorna uma lista com todos os imóveis cadastrados.
  Future<List<Imovel>> getTodosImoveis() async {
    final db = await _dbHelper.database;
    final maps = await db.query('imoveis', orderBy: 'dataCadastro DESC');
    return List.generate(maps.length, (i) => Imovel.fromMap(maps[i]));
  }

  /// Deleta um imóvel do banco de dados local.
  Future<void> deleteImovel(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'imoveis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}