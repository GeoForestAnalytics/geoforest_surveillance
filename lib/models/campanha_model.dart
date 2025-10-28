// lib/models/campanha_model.dart

class Campanha {
  final int? id;
  final String licenseId;
  final String nome; // Ex: "Campanha de Verão 2025" ou "Cadastro Geral de Imóveis"
  final String orgaoResponsavel; // Ex: "Secretaria de Saúde de Sorocaba"
  final DateTime dataCriacao;
  final String status; // 'ativa', 'concluida', 'arquivada'
  
  // =======================================================
  // >> NOVOS CAMPOS ADICIONADOS AQUI <<
  // =======================================================
  /// Define o propósito da campanha. Ex: 'dengue', 'covid', 'cadastro'.
  final String tipoCampanha;
  /// Nome do responsável técnico pela campanha.
  final String? responsavelTecnico;
  /// Cor para representar os setores desta campanha no mapa (armazenada como string, ex: '0xFF00838F').
  final String? corSetor;

  Campanha({
    this.id,
    required this.licenseId,
    required this.nome,
    required this.orgaoResponsavel,
    required this.dataCriacao,
    this.status = 'ativa',
    // Adicionados ao construtor
    required this.tipoCampanha,
    this.responsavelTecnico,
    this.corSetor,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'licenseId': licenseId,
      'nome': nome,
      'orgaoResponsavel': orgaoResponsavel,
      'dataCriacao': dataCriacao.toIso8601String(),
      'status': status,
      // Adicionados ao map
      'tipoCampanha': tipoCampanha,
      'responsavelTecnico': responsavelTecnico,
      'corSetor': corSetor,
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
      // Lidos do map (com valor padrão para dados antigos)
      tipoCampanha: map['tipoCampanha'] ?? 'dengue',
      responsavelTecnico: map['responsavelTecnico'],
      corSetor: map['corSetor'],
    );
  }

  /// Método de cópia para facilitar a edição
  Campanha copyWith({
    int? id,
    String? licenseId,
    String? nome,
    String? orgaoResponsavel,
    DateTime? dataCriacao,
    String? status,
    String? tipoCampanha,
    String? responsavelTecnico,
    String? corSetor,
  }) {
    return Campanha(
      id: id ?? this.id,
      licenseId: licenseId ?? this.licenseId,
      nome: nome ?? this.nome,
      orgaoResponsavel: orgaoResponsavel ?? this.orgaoResponsavel,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
      tipoCampanha: tipoCampanha ?? this.tipoCampanha,
      responsavelTecnico: responsavelTecnico ?? this.responsavelTecnico,
      corSetor: corSetor ?? this.corSetor,
    );
  }
}