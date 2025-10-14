// lib/models/diario_de_campo_model.dart

class DiarioDeCampo {
  final int? id;
  final String dataRelatorio; // Formato YYYY-MM-DD
  final String nomeLider;
  final int campanhaId; // ID da campanha principal do dia
  // Opcional: pode-se adicionar uma lista de bairros visitados
  final double? kmInicial;
  final double? kmFinal;
  final String? localizacaoDestino;
  final double? pedagioValor;
  final double? abastecimentoValor;
  final int? alimentacaoMarmitasQtd;
  final double? alimentacaoRefeicaoValor;
  final String? alimentacaoDescricao;
  final double? outrasDespesasValor;
  final String? outrasDespesasDescricao;
  final String? veiculoPlaca;
  final String? veiculoModelo;
  final String? equipeNoCarro;
  final String lastModified;

  DiarioDeCampo({
    this.id,
    required this.dataRelatorio,
    required this.nomeLider,
    required this.campanhaId,
    this.kmInicial,
    this.kmFinal,
    this.localizacaoDestino,
    this.pedagioValor,
    this.abastecimentoValor,
    this.alimentacaoMarmitasQtd,
    this.alimentacaoRefeicaoValor,
    this.alimentacaoDescricao,
    this.outrasDespesasValor,
    this.outrasDespesasDescricao,
    this.veiculoPlaca,
    this.veiculoModelo,
    this.equipeNoCarro,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_relatorio': dataRelatorio,
      'nome_lider': nomeLider,
      'campanha_id': campanhaId,
      'km_inicial': kmInicial,
      'km_final': kmFinal,
      'localizacao_destino': localizacaoDestino,
      'pedagio_valor': pedagioValor,
      'abastecimento_valor': abastecimentoValor,
      'alimentacao_marmitas_qtd': alimentacaoMarmitasQtd,
      'alimentacao_refeicao_valor': alimentacaoRefeicaoValor,
      'alimentacao_descricao': alimentacaoDescricao,
      'outras_despesas_valor': outrasDespesasValor,
      'outras_despesas_descricao': outrasDespesasDescricao,
      'veiculo_placa': veiculoPlaca,
      'veiculo_modelo': veiculoModelo,
      'equipe_no_carro': equipeNoCarro,
      'lastModified': lastModified,
    };
  }

  factory DiarioDeCampo.fromMap(Map<String, dynamic> map) {
    return DiarioDeCampo(
      id: map['id'],
      dataRelatorio: map['data_relatorio'],
      nomeLider: map['nome_lider'],
      campanhaId: map['campanha_id'],
      kmInicial: (map['km_inicial'] as num?)?.toDouble(),
      kmFinal: (map['km_final'] as num?)?.toDouble(),
      localizacaoDestino: map['localizacao_destino'],
      pedagioValor: (map['pedagio_valor'] as num?)?.toDouble(),
      abastecimentoValor: (map['abastecimento_valor'] as num?)?.toDouble(),
      alimentacaoMarmitasQtd: map['alimentacao_marmitas_qtd'],
      alimentacaoRefeicaoValor: (map['alimentacao_refeicao_valor'] as num?)?.toDouble(),
      alimentacaoDescricao: map['alimentacao_descricao'],
      outrasDespesasValor: (map['outras_despesas_valor'] as num?)?.toDouble(),
      outrasDespesasDescricao: map['outras_despesas_descricao'],
      veiculoPlaca: map['veiculo_placa'],
      veiculoModelo: map['veiculo_modelo'],
      equipeNoCarro: map['equipe_no_carro'],
      lastModified: map['lastModified'],
    );
  }
}