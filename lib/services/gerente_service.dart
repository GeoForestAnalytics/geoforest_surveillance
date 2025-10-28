// lib/services/gerente_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Imports Adaptados e Novos
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/diario_de_campo_model.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';

class GerenteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função genérica para combinar streams de várias licenças
  Stream<List<T>> _getAggregatedStream<T>({
    required List<String> licenseIds,
    required String collectionName,
    required T Function(Map<String, dynamic>) fromMap,
  }) {
    if (licenseIds.isEmpty) return Stream.value([]);

    final controller = StreamController<List<T>>();
    final subscriptions = <StreamSubscription>[];
    final allData = <String, List<T>>{}; // Mapa para guardar os dados de cada licença

    void updateStream() {
      final aggregatedList = allData.values.expand((list) => list).toList();
      controller.add(aggregatedList);
    }

    for (final licenseId in licenseIds) {
      final stream = _firestore.collection('clientes').doc(licenseId).collection(collectionName).snapshots();
      final subscription = stream.listen(
        (snapshot) {
          try {
            final dataList = snapshot.docs.map((doc) => fromMap(doc.data())).toList();
            allData[licenseId] = dataList;
            updateStream();
          } catch (e) {
            debugPrint("Erro ao converter dados do stream para $licenseId/$collectionName: $e");
          }
        },
        onError: (e) => debugPrint("Erro no stream para $licenseId/$collectionName: $e"),
      );
      subscriptions.add(subscription);
    }

    controller.onCancel = () {
      for (var sub in subscriptions) {
        sub.cancel();
      }
    };
    return controller.stream;
  }
  
  // =======================================================
  // >> NOVOS STREAMS ADICIONADOS AQUI <<
  // =======================================================

  /// Stream para os Imóveis cadastrados.
  Stream<List<Imovel>> getImoveisStream({required List<String> licenseIds}) {
    return _getAggregatedStream<Imovel>(
      licenseIds: licenseIds,
      collectionName: 'imoveis',
      fromMap: Imovel.fromMap,
    );
  }

  /// Stream para as Visitas realizadas.
  Stream<List<Visita>> getVisitasStream({required List<String> licenseIds}) {
    return _getAggregatedStream<Visita>(
      licenseIds: licenseIds,
      collectionName: 'visitas',
      fromMap: Visita.fromMap,
    );
  }

  // =======================================================
  // >> STREAMS ANTIGOS MANTIDOS PARA COMPATIBILIDADE <<
  // =======================================================

  /// Stream para os Focos de Dengue (Modelo Legado).
  Stream<List<FocoDengue>> getFocosStream({required List<String> licenseIds}) {
    return _getAggregatedStream<FocoDengue>(
      licenseIds: licenseIds,
      collectionName: 'focos_dengue', // Nome da coleção no Firestore
      fromMap: FocoDengue.fromMap,
    );
  }

  /// Stream para os Diários de Campo.
  Stream<List<DiarioDeCampo>> getDadosDiarioStream({required List<String> licenseIds}) {
    return _getAggregatedStream<DiarioDeCampo>(
      licenseIds: licenseIds,
      collectionName: 'diarios_de_campo',
      fromMap: DiarioDeCampo.fromMap,
    );
  }
}