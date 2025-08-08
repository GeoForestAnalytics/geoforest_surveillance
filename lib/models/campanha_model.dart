// lib/models/campanha_model.dart

class Campanha {
  final int? id;
  final String licenseId;
  final String nome; // Ex: "Campanha de Verão 2025"
  final String orgaoResponsavel; // Ex: "Secretaria de Saúde de Sorocaba"
  final DateTime dataCriacao;
  final String status; // 'ativa', 'concluida', 'arquivada'

  Campanha({
    this.id,
    required this.licenseId,
    required this.nome,
    required this.orgaoResponsavel,
    required this.dataCriacao,
    this.status = 'ativa',
  });
  
  // toMap e fromMap precisam ser atualizados para os novos nomes de campos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'licenseId': licenseId,
      'nome': nome,
      'orgaoResponsavel': orgaoResponsavel,
      'dataCriacao': dataCriacao.toIso8601String(),
      'status': status,
    };
  }

  factory Campanha.fromMap(Map<String, dynamic> map) {
    return Campanha(
      id: map['id'],
      licenseId: map['licenseId'],
      nome: map['nome'],
      orgaoResponsavel: map['orgaoResponsavel'],
      dataCriacao: DateTime.parse(map['dataCriacao']),
      status: map['status'] ?? 'ativo',
    );
  }
}