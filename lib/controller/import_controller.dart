// Arquivo: lib/controller/import_controller.dart (VERSÃO CORRIGIDA E FINAL)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

// Nossos Models e Providers
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/municipio_model.dart'; // <<< ADICIONADO
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';

class ImportController with ChangeNotifier {
  final BuildContext context;
  // =======================================================
  // >> CORREÇÃO 1: REMOVIDA A INICIALIZAÇÃO DO DB AQUI <<
  // Acessaremos o banco de forma assíncrona dentro da função
  // =======================================================

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

  Future<Map<String, dynamic>> validarGeoJson(File geojsonFile) async {
    try {
      final content = await geojsonFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (data['type'] != 'FeatureCollection' || data['features'] is! List || (data['features'] as List).isEmpty) {
        throw Exception("O arquivo não é uma FeatureCollection válida ou está vazio.");
      }
      
      final firstFeature = (data['features'] as List).first as Map<String, dynamic>;
      final properties = firstFeature['properties'] as Map<String, dynamic>?;

      if (properties == null || properties['posto_saud'] == null || properties['setor_nome'] == null) {
        throw Exception("As propriedades 'posto_saud' e 'setor_nome' são obrigatórias em cada feature do GeoJSON.");
      }
      return data;
    } catch (e) {
      // Repassa o erro com uma mensagem mais amigável
      throw Exception("Erro ao ler ou validar o arquivo GeoJSON. Verifique o formato. Detalhe: ${e.toString()}");
    }
  }
  
  Future<bool> processarImportacao({
    required File geojsonFile,
    required String nomeCampanha,
    required String orgao,
    required String nomeAcao,
    required String municipioIdPadrao,
    required String municipioNome, // <<< ADICIONADO
    required String municipioUf,   // <<< ADICIONADO
  }) async {
    _setLoading(true);

    try {
      final mapa = await validarGeoJson(geojsonFile);
      final licenseId = context.read<LicenseProvider>().licenseData!.id;
      
      // =======================================================
      // >> CORREÇÃO 2: OBTÉM INSTÂNCIA DO BANCO AQUI <<
      // =======================================================
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // PASSO A: CRIAR A BASE (CAMPANHA, AÇÃO E MUNICÍPIO)
        final novaCampanha = Campanha(licenseId: licenseId, nome: nomeCampanha, orgaoResponsavel: orgao, dataCriacao: DateTime.now());
        final campanhaId = await txn.insert('campanhas', novaCampanha.toMap());

        final novaAcao = Acao(campanhaId: campanhaId, tipo: nomeAcao, dataCriacao: DateTime.now());
        final acaoId = await txn.insert('acoes', novaAcao.toMap());

        final novoMunicipio = Municipio(id: municipioIdPadrao, acaoId: acaoId, nome: municipioNome, uf: municipioUf);
        await txn.insert('municipios', novoMunicipio.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
        
        // PASSO B: PROCESSAR CADA SETOR DO MAPA
        final Map<String, int> postosJaProcessados = {};

        for (var feature in mapa['features']) {
          final properties = feature['properties'];
          final geometria = feature['geometry'];
          
          final nomePosto = properties['posto_saud'] as String;
          final nomeSetor = properties['setor_nome'] as String;
          int postoId;

          // =======================================================
          // >> CORREÇÃO 3: LÓGICA "GET OR CREATE" IMPLEMENTADA <<
          // =======================================================
          if (postosJaProcessados.containsKey(nomePosto)) {
            postoId = postosJaProcessados[nomePosto]!;
          } else {
            final List<Map<String, dynamic>> postoExistente = await txn.query(
              'postos', 
              columns: ['id'],
              where: 'nome = ? AND licenseId = ?', 
              whereArgs: [nomePosto, licenseId],
              limit: 1
            );
            
            if (postoExistente.isNotEmpty) {
              postoId = postoExistente.first['id'] as int;
            } else {
              postoId = await txn.insert('postos', {'nome': nomePosto, 'licenseId': licenseId});
            }
            postosJaProcessados[nomePosto] = postoId;
          }

          // =======================================================
          // >> CORREÇÃO 4: CRIAÇÃO DO BAIRRO COM OS NOVOS CAMPOS <<
          // =======================================================
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
      return true; // Sucesso

    } catch (e) {
      _setError("Falha na importação: ${e.toString()}");
      return false; // Falha
    }
  }
}