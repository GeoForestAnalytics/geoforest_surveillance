// Arquivo: lib\models\acao_model.dart
class Acao {
  final int? id;
  final int campanhaId;
  final String tipo; // Ex: "Visita de Agentes", "Mutirão de Limpeza"
  final String? descricao;
  final DateTime dataCriacao;

  Acao({
    this.id,
    required this.campanhaId,
    required this.tipo,
    this.descricao,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campanhaId': campanhaId,
      'tipo': tipo,
      'descricao': descricao,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Acao.fromMap(Map<String, dynamic> map) {
    return Acao(
      id: map['id'],
      campanhaId: map['campanhaId'],
      tipo: map['tipo'],
      descricao: map['descricao'],
      dataCriacao: DateTime.parse(map['dataCriacao']),
    );
  }
}