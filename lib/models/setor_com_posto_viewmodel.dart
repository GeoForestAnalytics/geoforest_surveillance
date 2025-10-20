// Arquivo: lib/models/setor_com_posto_viewmodel.dart

import 'package:geo_forest_surveillance/models/bairro_model.dart';

// Esta é uma classe simples que agrupa um objeto 'Bairro' (nosso setor)
// com o nome do Posto de Saúde ao qual ele pertence.
// Usaremos isso para facilitar a exibição dos dados na tela.

class SetorComPosto {
  final Bairro bairro;
  final String nomePosto;

  SetorComPosto({
    required this.bairro,
    required this.nomePosto,
  });
}