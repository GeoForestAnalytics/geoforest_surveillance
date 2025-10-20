// lib/models/bairro_model.dart (VERSÃO CORRIGIDA E ATUALIZADA)

class Bairro {
  final int? id;
  final String municipioId;
  final int acaoId;
  final int? postoId; // <<< CAMPO ADICIONADO
  final String nome;
  final String? responsavelSetor;
  final String? geometria; // <<< CAMPO ADICIONADO

  Bairro({
    this.id,
    required this.municipioId,
    required this.acaoId,
    this.postoId, // <<< ATUALIZADO
    required this.nome,
    this.responsavelSetor,
    this.geometria, // <<< ATUALIZADO
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'municipioId': municipioId,
      'acaoId': acaoId,
      'postoId': postoId, // <<< ADICIONADO
      'nome': nome,
      'responsavelSetor': responsavelSetor,
      'geometria': geometria, // <<< ADICIONADO
    };
  }

  factory Bairro.fromMap(Map<String, dynamic> map) {
    return Bairro(
      id: map['id'],
      municipioId: map['municipioId'],
      acaoId: map['acaoId'],
      postoId: map['postoId'], // <<< ADICIONADO
      nome: map['nome'],
      responsavelSetor: map['responsavelSetor'],
      geometria: map['geometria'], // <<< ADICIONADO
    );
  }
}