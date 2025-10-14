// lib/providers/team_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamProvider with ChangeNotifier {
  String? _lider;
  String? _ajudantes;
  bool _isLoaded = false;

  String? get lider => _lider;
  String? get ajudantes => _ajudantes;
  bool get isLoaded => _isLoaded;

  TeamProvider() {
    // Carrega os dados do SharedPreferences assim que o provider é inicializado.
    loadTeam();
  }

  /// Carrega os nomes da equipe salvos localmente no dispositivo.
  Future<void> loadTeam() async {
    final prefs = await SharedPreferences.getInstance();
    _lider = prefs.getString('nome_lider');
    _ajudantes = prefs.getString('nomes_ajudantes');
    _isLoaded = true; // Marca como carregado para o GoRouter poder prosseguir
    notifyListeners();
  }

  /// Salva os nomes da equipe no dispositivo para uso futuro.
  Future<void> setTeam(String novoLider, String novosAjudantes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome_lider', novoLider);
    await prefs.setString('nomes_ajudantes', novosAjudantes);

    _lider = novoLider;
    _ajudantes = novosAjudantes;
    notifyListeners(); // Notifica os widgets (e o GoRouter) que os dados mudaram
  }
}