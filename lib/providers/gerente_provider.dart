import 'dart:async';
import 'package.flutter/material.dart';
import 'package.firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

// Imports atualizados para os modelos e repositórios de Dengue
import 'package:geo_dengue_monitor/models/foco_dengue_model.dart';
import 'package:geo_dengue_monitor/models/diario_de_campo_model.dart';
import 'package:geo_dengue_monitor/models/campanha_model.dart';
import 'package:geo_dengue_monitor/models/acao_model.dart';
import 'package:geo_dengue_monitor/models/bairro_model.dart';
import 'package:geo_dengue_monitor/data/repositories/campanha_repository.dart';
import 'package:geo_dengue_monitor/data/repositories/acao_repository.dart';
import 'package:geo_dengue_monitor/data/repositories/bairro_repository.dart';
import 'package:geo_dengue_monitor/services/gerente_service.dart'; // Será adaptado
import 'package:geo_dengue_monitor/services/licensing_service.dart';

class GerenteProvider with ChangeNotifier {
  final GerenteService _gerenteService = GerenteService();
  final CampanhaRepository _campanhaRepository = CampanhaRepository();
  final AcaoRepository _acaoRepository = AcaoRepository();
  final BairroRepository _bairroRepository = BairroRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LicensingService _licensingService = LicensingService();

  StreamSubscription? _focosSubscription;
  StreamSubscription? _diariosSubscription;

  // Listas de dados brutos e mapas auxiliares
  List<FocoDengue> _focosSincronizados = [];
  List<DiarioDeCampo> _diariosSincronizados = [];
  List<Campanha> _campanhas = [];
  List<Acao> _acoes = [];
  List<Bairro> _bairros = [];
  Map<int, String> _bairroIdToNomeMap = {};
  Map<int, int> _bairroToCampanhaMap = {};

  bool _isLoading = true;
  String? _error;
  
  // Getters públicos para a UI
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Campanha> get campanhas => _campanhas;
  List<Acao> get acoes => _acoes;
  List<Bairro> get bairros => _bairros;
  List<FocoDengue> get focosSincronizados => _focosSincronizados;
  List<DiarioDeCampo> get diariosSincronizados => _diariosSincronizados;

  // <<< GETTER ESSENCIAL PARA O MAPA E DASHBOARD >>>
  // Este getter retorna a lista de focos já com o nome do bairro preenchido
  List<FocoDengue> get focosFiltrados {
      return _focosSincronizados.map((foco) {
          return foco.copyWith(
              bairroNome: _bairroIdToNomeMap[foco.bairroId] ?? 'Desconhecido',
              // A campanhaId já vem no foco, então não precisamos buscar
          );
      }).toList();
  }


  GerenteProvider() {
    // Pode ser necessário inicializar formatação de data se for usar
    // initializeDateFormatting('pt_BR', null);
  }

  /// Busca no banco local por campanhas que foram delegadas.
  Future<Set<String>> _getDelegatedLicenseIds() async {
    // TODO: Adicionar lógica de delegação se for mantida no app de dengue.
    // Por enquanto, retorna um conjunto vazio.
    return {};
  }

  /// Inicia o monitoramento dos dados do Firestore.
  Future<void> iniciarMonitoramento() async {
    _focosSubscription?.cancel();
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
      
      // Carrega a hierarquia local para referência
      await _buildAuxiliaryMaps(ownLicenseId);

      // Ouve os streams de dados do Firestore
      _focosSubscription = _gerenteService.getFocosStream(licenseIds: allLicenseIdsToMonitor).listen(
        (listaDeFocos) {
          _focosSincronizados = listaDeFocos;
          if (_isLoading) _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = "Erro ao buscar dados de focos: $e";
          _isLoading = false;
          notifyListeners();
        },
      );

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

  /// Cria mapas auxiliares para enriquecer os dados vindos do Firestore.
  Future<void> _buildAuxiliaryMaps(String licenseId) async {
    _campanhas = await _campanhaRepository.getTodasCampanhas(licenseId);
    
    // TODO: Criar método _acaoRepository.getTodasAcoes()
    // _acoes = await _acaoRepository.getTodasAcoes();
    
    // TODO: Criar método _bairroRepository.getTodosBairros()
    // _bairros = await _bairroRepository.getTodosBairros();
    
    _bairroIdToNomeMap = { for (var bairro in _bairros) if (bairro.id != null) bairro.id!: bairro.nome };

    // Mapeia bairro -> acao -> campanha
    final Map<int, int> bairroToAcaoMap = { for (var b in _bairros) if(b.id != null) b.id! : b.acaoId };
    final Map<int, int> acaoToCampanhaMap = { for (var a in _acoes) if(a.id != null) a.id! : a.campanhaId };
    _bairroToCampanhaMap = bairroToAcaoMap.map((bairroId, acaoId) {
        return MapEntry(bairroId, acaoToCampanhaMap[acaoId] ?? 0);
    });
  }

  @override
  void dispose() {
    _focosSubscription?.cancel();
    _diariosSubscription?.cancel();
    super.dispose();
  }
}