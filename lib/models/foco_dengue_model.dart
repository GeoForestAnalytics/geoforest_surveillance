// lib/models/foco_dengue_model.dart
import 'package:uuid/uuid.dart';

// Enum para o tipo de local visitado
enum TipoLocal {
  residencia,
  terrenoBaldio,
  comercio,
  pontoEstrategico, // Ex: borracharia, ferro-velho
  outro
}

// Enum para o resultado da visita
enum StatusFoco {
  focoEliminado, // Encontrou larvas e tratou/eliminou
  potencial,     // Encontrou recipientes com água, mas sem larvas
  tratado,       // Aplicou larvicida
  recusado,      // Morador não permitiu a entrada
  fechado,       // Imóvel estava fechado
  semFoco        // Visitou e não encontrou nada de risco
}

class FocoDengue {
  int? id;
  String uuid;
  int bairroId;

  // --- DADOS DE LOCALIZAÇÃO ---
  String endereco;
  double latitude;
  double longitude;
  DateTime dataVisita;
  
  // --- DADOS DA COLETA ---
  TipoLocal tipoLocal;
  StatusFoco statusFoco;
  List<String> recipientes;
  int? amostrasColetadas;
  String? tratamentoRealizado;
  String? observacao;
  List<String> photoPaths;

  // --- DADOS DO AGENTE ---
  String nomeAgente;
  int campanhaId;
  String? bairroNome; // Campo auxiliar para relatórios

  // Controle de Sincronização
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
    this.photoPaths = const [],
    required this.nomeAgente,
    required this.campanhaId,
    this.bairroNome,
    this.isSynced = false,
  }) : uuid = uuid ?? const Uuid().v4();

  // <<< ADICIONE ESTE MÉTODO AQUI >>>
  FocoDengue copyWith({
    int? id,
    String? uuid,
    int? bairroId,
    String? endereco,
    double? latitude,
    double? longitude,
    DateTime? dataVisita,
    TipoLocal? tipoLocal,
    StatusFoco? statusFoco,
    List<String>? recipientes,
    int? amostrasColetadas,
    String? tratamentoRealizado,
    String? observacao,
    List<String>? photoPaths,
    String? nomeAgente,
    int? campanhaId,
    String? bairroNome,
    bool? isSynced,
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
      photoPaths: photoPaths ?? this.photoPaths,
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
      'photoPaths': photoPaths.join(','),
      'nomeAgente': nomeAgente,
      'campanhaId': campanhaId,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory FocoDengue.fromMap(Map<String, dynamic> map) {
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
      recipientes: (map['recipientes'] as String?)?.split(',') ?? [],
      amostrasColetadas: map['amostrasColetadas'],
      tratamentoRealizado: map['tratamentoRealizado'],
      observacao: map['observacao'],
      photoPaths: (map['photoPaths'] as String?)?.split(',') ?? [],
      nomeAgente: map['nomeAgente'],
      campanhaId: map['campanhaId'],
      isSynced: map['isSynced'] == 1,
    );
  }
}