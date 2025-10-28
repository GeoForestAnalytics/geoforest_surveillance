// lib/providers/gerente_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Imports da nova arquitetura
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/models/diario_de_campo_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';
import 'package:geo_forest_surveillance/services/gerente_service.dart';
import 'package:geo_forest_surveillance/services/licensing_service.dart';

/// Classe ViewModel que combina uma Visita com os dados do seu respectivo Imóvel.
/// Isso facilita a exibição de dados completos na UI (mapas, dashboards, etc.).
class VisitaEnriquecida {
  final Visita visita;
  final Imovel imovel;

  VisitaEnriquecida({required this.visita, required this.imovel});
}

class GerenteProvider with ChangeNotifier {
  final GerenteService _gerenteService = GerenteService();
  final CampanhaRepository _campanhaRepository = CampanhaRepository();
  final AcaoRepository _acaoRepository = AcaoRepository();
  final BairroRepository _bairroRepository = BairroRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LicensingService _licensingService = LicensingService();

  // Subscriptions para os streams do Firestore
  StreamSubscription? _imoveisSubscription;
  StreamSubscription? _visitasSubscription;
  StreamSubscription? _diariosSubscription;

  // Listas de dados brutos e mapas auxiliares
  List<Imovel> _imoveisSincronizados = [];
  List<Visita> _visitasSincronizadas = [];
  List<DiarioDeCampo> _diariosSincronizados = [];
  
  List<Campanha> _campanhas = [];
  List<Acao> _acoes = [];
  List<Bairro> _bairros = [];
  Map<int, Imovel> _imovelIdToImovelMap = {};

  bool _isLoading = true;
  String? _error;
  
  // Getters públicos para a UI
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Campanha> get campanhas => _campanhas;
  List<Acao> get acoes => _acoes;
  List<Bairro> get bairros => _bairros;
  List<Imovel> get imoveisSincronizados => _imoveisSincronizados;
  List<Visita> get visitasSincronizadas => _visitasSincronizadas;
  List<DiarioDeCampo> get diariosSincronizados => _diariosSincronizados;

  /// Getter principal para a UI: retorna a lista de visitas já com os dados do imóvel associado.
  List<VisitaEnriquecida> get visitasEnriquecidas {
    return _visitasSincronizadas.map((visita) {
      final imovelAssociado = _imovelIdToImovelMap[visita.imovelId];
      // Se o imóvel não for encontrado (caso raro de inconsistência), criamos um placeholder.
      final imovel = imovelAssociado ?? Imovel(logradouro: 'Imóvel Desconhecido', latitude: 0, longitude: 0, dataCadastro: DateTime.now());
      return VisitaEnriquecida(visita: visita, imovel: imovel);
    }).toList();
  }

  GerenteProvider() {
    // A inicialização agora é chamada pela UI quando necessário.
  }

  Future<Set<String>> _getDelegatedLicenseIds() async {
    return {};
  }

  Future<void> iniciarMonitoramento() async {
    // Cancela subscriptions antigas para evitar leaks de memória
    _imoveisSubscription?.cancel();
    _visitasSubscription?.cancel();
    _diariosSubscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("Usuário não autenticado.");

      final licenseDoc = await _licensingService.findLicenseDocumentForUser(user);
      if (licenseDoc == null) throw Exception("Licença do usuário não encontrada.");
      
      final ownLicenseId = licenseDoc.id;
      final delegatedLicenseIds = await _getDelegatedLicenseIds();
      final allLicenseIdsToMonitor = {ownLicenseId, ...delegatedLicenseIds}.toList();
      
      await _buildAuxiliaryMaps(ownLicenseId);

      // Ouve o stream de Imóveis
      _imoveisSubscription = _gerenteService.getImoveisStream(licenseIds: allLicenseIdsToMonitor).listen(
        (listaDeImoveis) {
          _imoveisSincronizados = listaDeImoveis;
          // Reconstrói o mapa de lookup para acesso rápido
          _imovelIdToImovelMap = { for (var imovel in _imoveisSincronizados) if (imovel.id != null) imovel.id! : imovel };
          notifyListeners();
        },
        onError: (e) {
          _error = "Erro ao buscar dados de imóveis: $e";
          _isLoading = false;
          notifyListeners();
        },
      );
      
      // Ouve o stream de Visitas
      _visitasSubscription = _gerenteService.getVisitasStream(licenseIds: allLicenseIdsToMonitor).listen(
        (listaDeVisitas) {
          _visitasSincronizadas = listaDeVisitas;
          if (_isLoading) _isLoading = false; // A UI está pronta quando as visitas chegam
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = "Erro ao buscar dados de visitas: $e";
          _isLoading = false;
          notifyListeners();
        },
      );

      // Ouve o stream de Diários (mantido)
      _diariosSubscription = _gerenteService.getDadosDiarioStream(licenseIds: allLicenseIdsToMonitor).listen(
        (listaDeDiarios) {
          _diariosSincronizados = listaDeDiarios;
          notifyListeners();
        },
        onError: (e) => debugPrint("Erro no stream de diários de campo: $e"),
      );

    } catch (e) {
      _error = "Erro ao iniciar monitoramento: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega dados do banco de dados local para serem usados como referência.
  Future<void> _buildAuxiliaryMaps(String licenseId) async {
    // Corrigindo os TODOs e carregando os dados locais
    _campanhas = await _campanhaRepository.getTodasAsCampanhasParaGerente();
    _acoes = await _acaoRepository.getTodasAcoes();
    _bairros = await _bairroRepository.getTodosBairros();
  }

  @override
  void dispose() {
    _imoveisSubscription?.cancel();
    _visitasSubscription?.cancel();
    _diariosSubscription?.cancel();
    super.dispose();
  }
}