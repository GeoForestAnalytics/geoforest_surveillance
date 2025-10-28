// Arquivo: lib/models/visita_model.dart (NOVO ARQUIVO)

import 'dart:convert';
import 'package:uuid/uuid.dart';

class Visita {
  final int? id;
  final String uuid;
  final int imovelId;
  final int campanhaId;
  final int acaoId;
  final DateTime dataVisita;
  final String nomeAgente;
  final String? nomeResponsavelAtendimento;
  
  /// Campo flexível para armazenar um JSON com os dados do formulário.
  final String? dadosFormulario;
  
  final List<String> photoPaths;
  final String? observacao;
  final bool isSynced;

  Visita({
    this.id,
    String? uuid,
    required this.imovelId,
    required this.campanhaId,
    required this.acaoId,
    required this.dataVisita,
    required this.nomeAgente,
    this.nomeResponsavelAtendimento,
    this.dadosFormulario,
    this.photoPaths = const [],
    this.observacao,
    this.isSynced = false,
  }) : uuid = uuid ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'imovelId': imovelId,
      'campanhaId': campanhaId,
      'acaoId': acaoId,
      'dataVisita': dataVisita.toIso8601String(),
      'nomeAgente': nomeAgente,
      'nomeResponsavelAtendimento': nomeResponsavelAtendimento,
      'dadosFormulario': dadosFormulario,
      'photoPaths': jsonEncode(photoPaths),
      'observacao': observacao,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Visita.fromMap(Map<String, dynamic> map) {
    List<String> decodedPaths = [];
    if (map['photoPaths'] is String) {
      try {
        final decoded = jsonDecode(map['photoPaths']);
        if (decoded is List) {
          decodedPaths = List<String>.from(decoded);
        }
      } catch (e) {
        // Fallback para formatos antigos ou inválidos
        decodedPaths = [];
      }
    }

    return Visita(
      id: map['id'],
      uuid: map['uuid'] ?? const Uuid().v4(),
      imovelId: map['imovelId'],
      campanhaId: map['campanhaId'],
      acaoId: map['acaoId'],
      dataVisita: DateTime.parse(map['dataVisita']),
      nomeAgente: map['nomeAgente'],
      nomeResponsavelAtendimento: map['nomeResponsavelAtendimento'],
      dadosFormulario: map['dadosFormulario'],
      photoPaths: decodedPaths,
      observacao: map['observacao'],
      isSynced: map['isSynced'] == 1,
    );
  }
}