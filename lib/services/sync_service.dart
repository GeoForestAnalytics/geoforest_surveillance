// lib/services/sync_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection/collection.dart';

// Imports adaptados
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/municipio_model.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/sync_progress_model.dart';
import 'package:geo_forest_surveillance/services/licensing_service.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';

class SyncService {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LicensingService _licensingService = LicensingService();
  final _focoRepository = FocoRepository();

  final StreamController<SyncProgress> _progressStreamController = StreamController.broadcast();
  Stream<SyncProgress> get progressStream => _progressStreamController.stream;
  
  // TODO: Implementar lógica de conflitos se necessário

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
      
      final totalFocos = (await _focoRepository.getUnsyncedFocos()).length;
      _progressStreamController.add(SyncProgress(totalAProcessar: totalFocos, mensagem: "Preparando sincronização..."));
      
      // 1. UPLOAD
      await _uploadColetasNaoSincronizadas(licenseId, totalFocos);
      
      // 2. DOWNLOAD
      _progressStreamController.add(SyncProgress(totalAProcessar: totalFocos, processados: totalFocos, mensagem: "Baixando dados da nuvem..."));
      await _downloadHierarquiaCompleta(licenseId);
      
      // TODO: Implementar download de dados delegados se necessário

      _progressStreamController.add(SyncProgress(totalAProcessar: totalFocos, processados: totalFocos, mensagem: "Sincronização Concluída!", concluido: true));

    } catch(e, s) {
      final erroMsg = "Erro na sincronização: $e";
      debugPrint("$erroMsg\n$s");
      _progressStreamController.add(SyncProgress(erro: erroMsg, concluido: true));
      rethrow;
    }
  }

  Future<void> _uploadColetasNaoSincronizadas(String licenseId, int totalGeral) async {
    int processados = 0;
    while(true) {
      final focosNaoSincronizados = await _focoRepository.getUnsyncedFocos();
      if (focosNaoSincronizados.isEmpty) break;

      final focoLocal = focosNaoSincronizados.first;
      
      _progressStreamController.add(SyncProgress(totalAProcessar: totalGeral, processados: processados, mensagem: "Enviando foco ${processados + 1} de $totalGeral..."));
      
      try {
        final docRef = _firestore.collection('clientes').doc(licenseId).collection('focos_dengue').doc(focoLocal.uuid);
        final focoMap = focoLocal.toMap();
        focoMap['lastModified'] = firestore.FieldValue.serverTimestamp();
        
        await docRef.set(focoMap, firestore.SetOptions(merge: true));
        await _focoRepository.markFocoAsSynced(focoLocal.uuid);
        processados++;
      } catch (e) {
        throw Exception("Falha ao enviar foco ${focoLocal.id}: $e");
      }
    }
  }
  
  Future<void> _downloadHierarquiaCompleta(String licenseId) async {
    final db = await _dbHelper.database;
    final collections = ['campanhas', 'acoes', 'municipios', 'bairros'];
    
    for (final collectionName in collections) {
      final snapshot = await _firestore.collection('clientes').doc(licenseId).collection(collectionName).get();
      await db.transaction((txn) async {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // Adiciona o ID do documento aos dados, pois ele não vem por padrão
          if (collectionName != 'municipios') { // Municípios usam chave composta
             data['id'] = int.tryParse(doc.id);
          }
          await txn.insert(collectionName, data, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }
  }
}