// lib/services/sync_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

// Imports adaptados e novos
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/models/sync_progress_model.dart';
import 'package:geo_forest_surveillance/services/licensing_service.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/imovel_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';

class SyncService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LicensingService _licensingService = LicensingService();

  // Adicionando os novos repositórios
  final _imovelRepository = ImovelRepository();
  final _visitaRepository = VisitaRepository();
  final _focoRepository = FocoRepository(); // Legado

  final StreamController<SyncProgress> _progressStreamController = StreamController.broadcast();
  Stream<SyncProgress> get progressStream => _progressStreamController.stream;
  
  Future<void> sincronizarDados() async {
    final user = _auth.currentUser;
    if (user == null) {
      _progressStreamController.add(SyncProgress(erro: "Usuário não logado.", concluido: true));
      return;
    }

    try {
      final licenseDoc = await _licensingService.findLicenseDocumentForUser(user);
      final licenseId = licenseDoc?.id;
      if (licenseId == null) throw Exception("Licença do usuário não encontrada.");
      
      // =======================================================
      // >> LÓGICA DE PROGRESSO ATUALIZADA <<
      // =======================================================
      _progressStreamController.add(SyncProgress(mensagem: "Verificando dados para sincronizar..."));
      
      final db = await _dbHelper.database;
      final imoveisNaoSincronizados = await db.query('imoveis', where: 'isSynced = 0');
      final visitasNaoSincronizadas = await db.query('visitas', where: 'isSynced = 0');
      final focosNaoSincronizados = await db.query('focos', where: 'isSynced = 0');

      final totalItems = imoveisNaoSincronizados.length + visitasNaoSincronizadas.length + focosNaoSincronizados.length;
      
      if (totalItems == 0) {
        _progressStreamController.add(SyncProgress(mensagem: "Nenhum dado novo para enviar. Baixando atualizações...", concluido: false));
      } else {
        _progressStreamController.add(SyncProgress(totalAProcessar: totalItems, mensagem: "Preparando sincronização..."));
      }
      
      int processados = 0;

      // 1. UPLOAD IMÓVEIS
      processados = await _uploadGenerico(
        licenseId: licenseId,
        items: imoveisNaoSincronizados.map((map) => Imovel.fromMap(map)).toList(),
        collectionName: 'imoveis',
        totalGeral: totalItems,
        processadosAteAgora: processados,
        itemName: 'imóvel',
        marcarComoSincronizado: (uuid) async {
          await db.update('imoveis', {'isSynced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
        }
      );
      
      // 2. UPLOAD VISITAS
      processados = await _uploadGenerico(
        licenseId: licenseId,
        items: visitasNaoSincronizadas.map((map) => Visita.fromMap(map)).toList(),
        collectionName: 'visitas',
        totalGeral: totalItems,
        processadosAteAgora: processados,
        itemName: 'visita',
        marcarComoSincronizado: (uuid) async {
           await db.update('visitas', {'isSynced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
        }
      );
      
      // 3. UPLOAD FOCOS (LEGADO)
      processados = await _uploadGenerico(
        licenseId: licenseId,
        items: focosNaoSincronizados.map((map) => FocoDengue.fromMap(map)).toList(),
        collectionName: 'focos_dengue',
        totalGeral: totalItems,
        processadosAteAgora: processados,
        itemName: 'foco (legado)',
        marcarComoSincronizado: (uuid) async {
          await _focoRepository.markFocoAsSynced(uuid);
        }
      );

      // 4. DOWNLOAD
      _progressStreamController.add(SyncProgress(totalAProcessar: totalItems, processados: totalItems, mensagem: "Baixando dados da nuvem..."));
      await _downloadHierarquiaCompleta(licenseId);
      
      _progressStreamController.add(SyncProgress(totalAProcessar: totalItems, processados: totalItems, mensagem: "Sincronização Concluída!", concluido: true));

    } catch(e, s) {
      final erroMsg = "Erro na sincronização: $e";
      debugPrint("$erroMsg\n$s");
      _progressStreamController.add(SyncProgress(erro: erroMsg, concluido: true));
      rethrow;
    }
  }

  // =======================================================
  // >> FUNÇÃO DE UPLOAD GENÉRICA CRIADA <<
  // =======================================================
  Future<int> _uploadGenerico({
    required String licenseId,
    required List<dynamic> items,
    required String collectionName,
    required int totalGeral,
    required int processadosAteAgora,
    required String itemName,
    required Future<void> Function(String) marcarComoSincronizado,
  }) async {
    int processadosNestaEtapa = 0;
    for (final item in items) {
      final itemMap = item.toMap();
      final uuid = item.uuid;
      
      _progressStreamController.add(SyncProgress(
        totalAProcessar: totalGeral,
        processados: processadosAteAgora + processadosNestaEtapa,
        mensagem: "Enviando $itemName ${processadosAteAgora + processadosNestaEtapa + 1} de $totalGeral...",
      ));
      
      try {
        final docRef = _firestore.collection('clientes').doc(licenseId).collection(collectionName).doc(uuid);
        itemMap['lastModified'] = firestore.FieldValue.serverTimestamp();
        
        await docRef.set(itemMap, firestore.SetOptions(merge: true));
        await marcarComoSincronizado(uuid);
        processadosNestaEtapa++;
      } catch (e) {
        throw Exception("Falha ao enviar $itemName $uuid: $e");
      }
    }
    return processadosAteAgora + processadosNestaEtapa;
  }
  
  Future<void> _downloadHierarquiaCompleta(String licenseId) async {
    final db = await _dbHelper.database;
    // Adicionamos 'postos' ao download para garantir que as coordenadas estejam sempre atualizadas.
    final collections = ['campanhas', 'acoes', 'municipios', 'bairros', 'postos'];
    
    for (final collectionName in collections) {
      final snapshot = await _firestore.collection('clientes').doc(licenseId).collection(collectionName).get();
      await db.transaction((txn) async {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // O Firestore não inclui o ID do documento no `data()`, então precisamos adicioná-lo.
          if (collectionName != 'municipios' && collectionName != 'postos') {
             data['id'] = int.tryParse(doc.id);
          } else if (collectionName == 'postos') {
             // A tabela 'postos' também usa ID numérico autoincremental localmente, mas não no Firestore.
             // Vamos confiar no 'nome' como chave única e usar 'replace'.
          }
          await txn.insert(collectionName, data, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }
  }
}