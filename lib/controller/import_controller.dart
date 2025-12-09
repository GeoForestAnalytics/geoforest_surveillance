// lib/controller/import_controller.dart (VERSÃO COMPLETA E FINAL)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection/collection.dart';

// Nossos Models e Providers
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/municipio_model.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';

class ImportController with ChangeNotifier {
  final BuildContext context;

  ImportController(this.context);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _validarGeoJsonGenerico(File geojsonFile) async {
    try {
      final content = await geojsonFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['type'] != 'FeatureCollection' ||
          data['features'] is! List ||
          (data['features'] as List).isEmpty) {
        throw Exception(
            "O arquivo não é uma FeatureCollection válida ou está vazio.");
      }
      return data;
    } catch (e) {
      throw Exception(
          "Erro ao ler o arquivo GeoJSON. Verifique o formato. Detalhe: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> validarGeoJsonPoligonos(File geojsonFile) async {
    final data = await _validarGeoJsonGenerico(geojsonFile);
    final firstFeature =
        (data['features'] as List).first as Map<String, dynamic>;
    final properties = firstFeature['properties'] as Map<String, dynamic>?;

    if (properties == null ||
        properties['posto_saud'] == null ||
        properties['setor_nome'] == null) {
      throw Exception(
          "As propriedades 'posto_saud' e 'setor_nome' são obrigatórias em cada feature do GeoJSON de polígonos.");
    }
    return data;
  }

  Future<Map<String, dynamic>> validarGeoJsonPontos(File geojsonFile) async {
    final data = await _validarGeoJsonGenerico(geojsonFile);
    final firstFeature =
        (data['features'] as List).first as Map<String, dynamic>;
    final properties = firstFeature['properties'] as Map<String, dynamic>?;
    final geometryType = firstFeature['geometry']?['type'];

    if (properties == null || properties['posto_saud'] == null) {
      throw Exception(
          "A propriedade 'posto_saud' é obrigatória em cada feature do GeoJSON de pontos.");
    }
    if (geometryType != 'Point') {
      throw Exception(
          "A geometria esperada para este arquivo é do tipo 'Point'.");
    }
    return data;
  }

  /// (MÉTODO ANTIGO) Para criar uma campanha nova a partir de um formulário completo.
  Future<bool> processarImportacao({
    required File geojsonFile,
    required String nomeCampanha,
    required String orgao,
    required String nomeAcao,
    required String municipioIdPadrao,
    required String municipioNome,
    required String municipioUf,
    required String tipoCampanha,
  }) async {
    _setLoading(true);

    try {
      final mapa = await validarGeoJsonPoligonos(geojsonFile);
      final licenseId = context.read<LicenseProvider>().licenseData!.id;
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        final novaCampanha = Campanha(
            licenseId: licenseId,
            nome: nomeCampanha,
            orgaoResponsavel: orgao,
            dataCriacao: DateTime.now(),
            tipoCampanha: tipoCampanha);
        final campanhaId = await txn.insert('campanhas', novaCampanha.toMap());

        final novaAcao = Acao(
            campanhaId: campanhaId,
            tipo: nomeAcao,
            dataCriacao: DateTime.now());
        final acaoId = await txn.insert('acoes', novaAcao.toMap());

        final novoMunicipio = Municipio(
            id: municipioIdPadrao,
            acaoId: acaoId,
            nome: municipioNome,
            uf: municipioUf);
        await txn.insert('municipios', novoMunicipio.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);

        final Map<String, int> postosJaProcessados = {};

        for (var feature in mapa['features']) {
          final properties = feature['properties'];
          final geometria = feature['geometry'];

          final nomePosto = properties['posto_saud'] as String;
          final nomeSetor = properties['setor_nome'] as String;
          int postoId;

          if (postosJaProcessados.containsKey(nomePosto)) {
            postoId = postosJaProcessados[nomePosto]!;
          } else {
            final List<Map<String, dynamic>> postoExistente = await txn.query(
                'postos',
                columns: ['id'],
                where: 'nome = ? AND licenseId = ?',
                whereArgs: [nomePosto, licenseId],
                limit: 1);

            if (postoExistente.isNotEmpty) {
              postoId = postoExistente.first['id'] as int;
            } else {
              postoId = await txn.insert(
                  'postos', {'nome': nomePosto, 'licenseId': licenseId});
            }
            postosJaProcessados[nomePosto] = postoId;
          }

          final novoBairro = Bairro(
            acaoId: acaoId,
            municipioId: municipioIdPadrao,
            postoId: postoId,
            nome: nomeSetor,
            geometria: jsonEncode(geometria),
          );
          await txn.insert('bairros', novoBairro.toMap());
        }
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Falha na importação: ${e.toString()}");
      return false;
    }
  }
  
  /// (MÉTODO ANTIGO) Para importar setores em uma ação existente, com formulário.
  Future<bool> processarImportacaoDeSetores({
    required File geojsonFile,
    required int acaoId,
    required String municipioId,
    required String municipioNome,
    required String municipioUf,
  }) async {
    _setLoading(true);

    try {
      final mapa = await validarGeoJsonPoligonos(geojsonFile);
      final licenseId = context.read<LicenseProvider>().licenseData!.id;
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        final novoMunicipio = Municipio(
            id: municipioId,
            acaoId: acaoId,
            nome: municipioNome,
            uf: municipioUf);
        await txn.insert('municipios', novoMunicipio.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);

        final Map<String, int> postosJaProcessados = {};

        for (var feature in mapa['features']) {
          final properties = feature['properties'];
          final geometria = feature['geometry'];

          final nomePosto = properties['posto_saud'] as String;
          final nomeSetor = properties['setor_nome'] as String;
          int postoId;

          if (postosJaProcessados.containsKey(nomePosto)) {
            postoId = postosJaProcessados[nomePosto]!;
          } else {
            final List<Map<String, dynamic>> postoExistente = await txn.query(
                'postos',
                columns: ['id'],
                where: 'nome = ? AND licenseId = ?',
                whereArgs: [nomePosto, licenseId],
                limit: 1);

            if (postoExistente.isNotEmpty) {
              postoId = postoExistente.first['id'] as int;
            } else {
              postoId = await txn.insert(
                  'postos', {'nome': nomePosto, 'licenseId': licenseId});
            }
            postosJaProcessados[nomePosto] = postoId;
          }

          final novoBairro = Bairro(
            acaoId: acaoId,
            municipioId: municipioId,
            postoId: postoId,
            nome: nomeSetor,
            geometria: jsonEncode(geometria),
          );
          await txn.insert('bairros', novoBairro.toMap());
        }
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Falha na importação dos setores: ${e.toString()}");
      return false;
    }
  }

  /// Para importar pontos (coordenadas) dos postos de saúde.
  Future<bool> processarImportacaoDePontos({
    required File geojsonFile,
  }) async {
    _setLoading(true);

    try {
      final mapa = await validarGeoJsonPontos(geojsonFile);
      final licenseId = context.read<LicenseProvider>().licenseData!.id;
      final db = await DatabaseHelper.instance.database;

      int postosAtualizados = 0;

      await db.transaction((txn) async {
        for (var feature in mapa['features']) {
          if (feature['geometry']?['type'] != 'Point') continue;

          final properties = feature['properties'];
          final geometria = feature['geometry'];

          final nomePosto = properties['posto_saud'] as String?;
          if (nomePosto == null || nomePosto.isEmpty) continue;

          final coordinates = geometria['coordinates'] as List;
          final longitude = coordinates[0] as double;
          final latitude = coordinates[1] as double;

          final count = await txn.update(
            'postos',
            {
              'latitude': latitude,
              'longitude': longitude,
            },
            where: 'nome = ? AND licenseId = ?',
            whereArgs: [nomePosto, licenseId],
          );

          if (count > 0) {
            postosAtualizados++;
          }
        }
      });

      _setLoading(false);
      debugPrint("$postosAtualizados postos de saúde foram atualizados com coordenadas.");
      return true;
    } catch (e) {
      _setError("Falha na importação dos pontos: ${e.toString()}");
      return false;
    }
  }

  /// >> NOVO MÉTODO PARA IMPORTAÇÃO AUTOMÁTICA <<
  /// Lê o GeoJSON, extrai os dados de municípios e setores, e salva tudo.
  Future<bool> processarGeoJsonCompleto({
    required File geojsonFile,
    required int acaoId,
  }) async {
    _setLoading(true);
    try {
      final content = await geojsonFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['type'] != 'FeatureCollection' || data['features'] is! List) {
        throw Exception("Arquivo GeoJSON inválido.");
      }
      
      final features = data['features'] as List;
      if (features.isEmpty) {
        throw Exception("O arquivo GeoJSON não contém nenhuma feature (polígono).");
      }

      final firstProps = features.first['properties'] as Map<String, dynamic>?;
      if (firstProps == null ||
          // Removida a validação de município aqui, pois pode não estar presente
          firstProps['setor_nome'] == null ||
          firstProps['posto_saud'] == null) {
        throw Exception("As propriedades 'setor_nome' e 'posto_saud' são obrigatórias em cada feature.");
      }

      final featuresPorMunicipio = groupBy(features, (feature) => (feature as Map)['properties']['municipio_id']?.toString() ?? 'municipio_padrao');
      
      final licenseId = context.read<LicenseProvider>().licenseData!.id;
      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        for (var entry in featuresPorMunicipio.entries) {
          final municipioId = entry.key;
          final setoresDoMunicipio = entry.value;
          
          final firstFeature = setoresDoMunicipio.first as Map;
          final props = firstFeature['properties'];
          final municipioNome = props['municipio_nome'] as String? ?? 'Município Padrão';
          final municipioUf = props['uf'] as String? ?? 'SP';

          if (municipioId != 'municipio_padrao') {
            await txn.insert(
              'municipios',
              Municipio(id: municipioId, acaoId: acaoId, nome: municipioNome, uf: municipioUf).toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          final Map<String, int> postosJaProcessados = {};
          for (var feature in setoresDoMunicipio) {
            final f = feature as Map;
            final properties = f['properties'];
            final geometria = f['geometry'];

            final nomePosto = properties['posto_saud'] as String;
            final nomeSetor = properties['setor_nome'] as String;
            int postoId;

            if (postosJaProcessados.containsKey(nomePosto)) {
              postoId = postosJaProcessados[nomePosto]!;
            } else {
              final List<Map<String, dynamic>> postoExistente = await txn.query(
                  'postos',
                  columns: ['id'],
                  where: 'nome = ? AND licenseId = ?',
                  whereArgs: [nomePosto, licenseId],
                  limit: 1);

              if (postoExistente.isNotEmpty) {
                postoId = postoExistente.first['id'] as int;
              } else {
                postoId = await txn.insert('postos', {'nome': nomePosto, 'licenseId': licenseId});
              }
              postosJaProcessados[nomePosto] = postoId;
            }

            final novoBairro = Bairro(
              acaoId: acaoId,
              municipioId: municipioId,
              postoId: postoId,
              nome: nomeSetor,
              geometria: jsonEncode(geometria),
            );
            await txn.insert('bairros', novoBairro.toMap());
          }
        }
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Falha na importação: ${e.toString()}");
      return false;
    }
  }
}