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

  // Atualize toMap e fromMap...
}