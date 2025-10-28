// Arquivo: lib/models/imovel_model.dart (NOVO ARQUIVO)

import 'package:uuid/uuid.dart';

class Imovel {
  final int? id;
  final String uuid;
  final int? bairroId; // Pode não estar associado a um setor pré-definido
  final String logradouro;
  final String? numero;
  final String? complemento;
  final String? cep;
  final double latitude;
  final double longitude;
  final String? tipoImovel; // Ex: 'Residência', 'Comércio', 'Terreno Baldio'
  final int? quantidadeMoradores;
  final double? rendaFamiliar;
  final DateTime dataCadastro;
  final bool isSynced;

  Imovel({
    this.id,
    String? uuid,
    this.bairroId,
    required this.logradouro,
    this.numero,
    this.complemento,
    this.cep,
    required this.latitude,
    required this.longitude,
    this.tipoImovel,
    this.quantidadeMoradores,
    this.rendaFamiliar,
    required this.dataCadastro,
    this.isSynced = false,
  }) : uuid = uuid ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'bairroId': bairroId,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
      'tipoImovel': tipoImovel,
      'quantidadeMoradores': quantidadeMoradores,
      'rendaFamiliar': rendaFamiliar,
      'dataCadastro': dataCadastro.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Imovel.fromMap(Map<String, dynamic> map) {
    return Imovel(
      id: map['id'],
      uuid: map['uuid'] ?? const Uuid().v4(),
      bairroId: map['bairroId'],
      logradouro: map['logradouro'],
      numero: map['numero'],
      complemento: map['complemento'],
      cep: map['cep'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      tipoImovel: map['tipoImovel'],
      quantidadeMoradores: map['quantidadeMoradores'],
      rendaFamiliar: map['rendaFamiliar'],
      dataCadastro: DateTime.parse(map['dataCadastro']),
      isSynced: map['isSynced'] == 1,
    );
  }
}