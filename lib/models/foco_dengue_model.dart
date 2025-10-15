// lib/models/foco_dengue_model.dart
import 'dart:convert'; // Import necessário para json
import 'package:uuid/uuid.dart';

// Enums permanecem os mesmos
enum TipoLocal { residencia, terrenoBaldio, comercio, pontoEstrategico, outro }
enum StatusFoco { focoEliminado, potencial, tratado, recusado, fechado, semFoco }

class FocoDengue {
  int? id;
  String uuid;
  int bairroId;
  String endereco;
  double latitude;
  double longitude;
  DateTime dataVisita;
  TipoLocal tipoLocal;
  StatusFoco statusFoco;
  List<String> recipientes;
  int? amostrasColetadas;
  String? tratamentoRealizado;
  String? observacao;
  List<String> photoPaths; // <<< CAMPO ATUALIZADO/ADICIONADO
  String nomeAgente;
  int campanhaId;
  String? bairroNome;
  bool isSynced;

  FocoDengue({
    this.id,
    String? uuid,
    required this.bairroId,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.dataVisita,
    required this.tipoLocal,
    required this.statusFoco,
    this.recipientes = const [],
    this.amostrasColetadas,
    this.tratamentoRealizado,
    this.observacao,
    this.photoPaths = const [], // <<< ATUALIZADO
    required this.nomeAgente,
    required this.campanhaId,
    this.bairroNome,
    this.isSynced = false,
  }) : uuid = uuid ?? const Uuid().v4();

  FocoDengue copyWith({
    int? id, String? uuid, int? bairroId, String? endereco, double? latitude,
    double? longitude, DateTime? dataVisita, TipoLocal? tipoLocal, StatusFoco? statusFoco,
    List<String>? recipientes, int? amostrasColetadas, String? tratamentoRealizado,
    String? observacao, List<String>? photoPaths, String? nomeAgente, int? campanhaId,
    String? bairroNome, bool? isSynced,
  }) {
    return FocoDengue(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bairroId: bairroId ?? this.bairroId,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dataVisita: dataVisita ?? this.dataVisita,
      tipoLocal: tipoLocal ?? this.tipoLocal,
      statusFoco: statusFoco ?? this.statusFoco,
      recipientes: recipientes ?? this.recipientes,
      amostrasColetadas: amostrasColetadas ?? this.amostrasColetadas,
      tratamentoRealizado: tratamentoRealizado ?? this.tratamentoRealizado,
      observacao: observacao ?? this.observacao,
      photoPaths: photoPaths ?? this.photoPaths, // <<< ATUALIZADO
      nomeAgente: nomeAgente ?? this.nomeAgente,
      campanhaId: campanhaId ?? this.campanhaId,
      bairroNome: bairroNome ?? this.bairroNome,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'bairroId': bairroId,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'dataVisita': dataVisita.toIso8601String(),
      'tipoLocal': tipoLocal.name,
      'statusFoco': statusFoco.name,
      'recipientes': recipientes.join(','),
      'amostrasColetadas': amostrasColetadas,
      'tratamentoRealizado': tratamentoRealizado,
      'observacao': observacao,
      'photoPaths': jsonEncode(photoPaths), // <<< ATUALIZADO PARA JSON
      'nomeAgente': nomeAgente,
      'campanhaId': campanhaId,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory FocoDengue.fromMap(Map<String, dynamic> map) {
    List<String> decodedPaths = [];
    if (map['photoPaths'] is String) {
      try {
        // Tenta decodificar como JSON
        final decoded = jsonDecode(map['photoPaths']);
        if (decoded is List) {
          decodedPaths = List<String>.from(decoded);
        }
      } catch (e) {
        // Fallback para o formato antigo (separado por vírgula)
        decodedPaths = (map['photoPaths'] as String).split(',').where((p) => p.isNotEmpty).toList();
      }
    }
    
    return FocoDengue(
      id: map['id'],
      uuid: map['uuid'] ?? const Uuid().v4(),
      bairroId: map['bairroId'],
      endereco: map['endereco'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      dataVisita: DateTime.parse(map['dataVisita']),
      tipoLocal: TipoLocal.values.firstWhere((e) => e.name == map['tipoLocal'], orElse: () => TipoLocal.outro),
      statusFoco: StatusFoco.values.firstWhere((e) => e.name == map['statusFoco'], orElse: () => StatusFoco.semFoco),
      recipientes: (map['recipientes'] as String?)?.split(',').where((r) => r.isNotEmpty).toList() ?? [],
      amostrasColetadas: map['amostrasColetadas'],
      tratamentoRealizado: map['tratamentoRealizado'],
      observacao: map['observacao'],
      photoPaths: decodedPaths, // <<< ATUALIZADO
      nomeAgente: map['nomeAgente'],
      campanhaId: map['campanhaId'],
      isSynced: map['isSynced'] == 1,
    );
  }
}