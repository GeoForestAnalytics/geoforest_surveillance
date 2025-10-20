// Arquivo: lib/data/repositories/bairro_repository.dart (VERSÃO ATUALIZADA)

import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';
// =======================================================
// >> IMPORT ADICIONADO AQUI <<
// =======================================================
import 'package:geo_forest_surveillance/models/setor_com_posto_viewmodel.dart';

class BairroRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

  // =======================================================
  // >> NOVO MÉTODO ADICIONADO AQUI <<
  // =======================================================
  /// Busca os setores (bairros) de um município em uma ação específica,
  /// já incluindo o nome do Posto de Saúde associado.
  Future<List<SetorComPosto>> getSetoresComPosto(String municipioId, int acaoId) async {
    final db = await _dbHelper.database;
    
    // Usamos uma consulta SQL crua com LEFT JOIN para buscar dados de ambas as tabelas.
    // O LEFT JOIN garante que, mesmo que um bairro não tenha um postoId definido, ele ainda apareça na lista.
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        b.id, b.municipioId, b.acaoId, b.postoId, b.nome, b.responsavelSetor, b.geometria,
        p.nome as nomePosto 
      FROM bairros b
      LEFT JOIN postos p ON b.postoId = p.id
      WHERE b.municipioId = ? AND b.acaoId = ?
      ORDER BY p.nome, b.nome
    ''', [municipioId, acaoId]);

    if (maps.isEmpty) {
      return [];
    }

    // Convertemos o resultado da consulta para a nossa nova classe de visualização
    return List.generate(maps.length, (i) {
      return SetorComPosto(
        bairro: Bairro.fromMap(maps[i]),
        nomePosto: maps[i]['nomePosto'] as String? ?? 'Não definido', // Garante que nunca será nulo
      );
    });
  }
}