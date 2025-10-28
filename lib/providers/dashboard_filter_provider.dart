// Arquivo: lib/providers/dashboard_filter_provider.dart (NOVO ARQUIVO)

import 'package:flutter/material.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';

class DashboardFilterProvider with ChangeNotifier {
  Campanha? _campanhaSelecionada;
  DateTimeRange? _periodoSelecionado;
  String? _agenteSelecionado;

  Campanha? get campanhaSelecionada => _campanhaSelecionada;
  DateTimeRange? get periodoSelecionado => _periodoSelecionado;
  String? get agenteSelecionado => _agenteSelecionado;

  void setCampanha(Campanha? campanha) {
    _campanhaSelecionada = campanha;
    notifyListeners();
  }

  void setPeriodo(DateTimeRange? periodo) {
    _periodoSelecionado = periodo;
    notifyListeners();
  }

  void setAgente(String? agente) {
    _agenteSelecionado = agente;
    notifyListeners();
  }

  void limparFiltros() {
    _campanhaSelecionada = null;
    _periodoSelecionado = null;
    _agenteSelecionado = null;
    notifyListeners();
  }
}