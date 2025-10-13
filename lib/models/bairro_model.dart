// lib/models/bairro_model.dart

class Bairro {
  final int? id;
  final String municipioId;
  final int acaoId; // ID da Ação/Ciclo
  final String nome; // Ex: "Centro", "Jd. Europa", "Setor 05"
  final String? responsavelSetor;

  Bairro({
    this.id,
    required this.municipioId,
    required this.acaoId,
    required this.nome,
    this.responsavelSetor,
  });

  // <<< CORREÇÃO AQUI: MÉTODOS ADICIONADOS >>>
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'municipioId': municipioId,
      'acaoId': acaoId,
      'nome': nome,
      'responsavelSetor': responsavelSetor,
    };
  }

  factory Bairro.fromMap(Map<String, dynamic> map) {
    return Bairro(
      id: map['id'],
      municipioId: map['municipioId'],
      acaoId: map['acaoId'],
      nome: map['nome'],
      responsavelSetor: map['responsavelSetor'],
    );
  }
}