// lib/providers/map_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/sample_point.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';

enum MapLayerType { ruas, satelite }

class MapProvider with ChangeNotifier {
  final _focoRepository = FocoRepository();

  // Estado do Mapa
  List<SamplePoint> _samplePoints = [];
  bool _isLoading = false;
  Acao? _currentAcao;
  MapLayerType _currentLayer = MapLayerType.satelite;

  // Estado do GPS
  Position? _currentUserPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFollowingUser = false;

  // Estado do Modo "Ir Para"
  SamplePoint? _goToTarget;

  // Getters Públicos
  List<SamplePoint> get samplePoints => _samplePoints;
  bool get isLoading => _isLoading;
  Acao? get currentAcao => _currentAcao;
  MapLayerType get currentLayer => _currentLayer;
  Position? get currentUserPosition => _currentUserPosition;
  bool get isFollowingUser => _isFollowingUser;
  SamplePoint? get goToTarget => _goToTarget;
  bool get isGoToModeActive => _goToTarget != null;

  final Map<MapLayerType, String> _tileUrls = {
    MapLayerType.ruas: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    MapLayerType.satelite: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  String get currentTileUrl => _tileUrls[_currentLayer]!;
  
  void switchMapLayer() {
    _currentLayer = MapLayerType.values[(_currentLayer.index + 1) % MapLayerType.values.length];
    notifyListeners();
  }

  void setCurrentAcao(Acao acao) {
    _currentAcao = acao;
    notifyListeners();
  }

  Future<void> loadPontosParaAcao() async {
    if (_currentAcao == null) return;
    _setLoading(true);
    _samplePoints.clear();

    // TODO: A lógica de carregar os focos precisa ser mais específica
    // Aqui estamos buscando TODOS os focos não sincronizados como exemplo
    final focos = await _focoRepository.getUnsyncedFocos();

    _samplePoints = focos.map((foco) {
      return SamplePoint(
        id: foco.id ?? 0,
        position: LatLng(foco.latitude, foco.longitude),
        status: _getSampleStatusFromFoco(foco),
        data: {'dbId': foco.id},
      );
    }).toList();
    
    _setLoading(false);
  }

  SampleStatus _getSampleStatusFromFoco(FocoDengue foco) {
    // Adapta o status específico do Foco para o status genérico do mapa
    switch (foco.statusFoco) {
      case StatusFoco.focoEliminado:
      case StatusFoco.tratado:
        return SampleStatus.completed;
      case StatusFoco.semFoco:
        return SampleStatus.completed; // Marcamos como completo também
      case StatusFoco.potencial:
        return SampleStatus.open;
      case StatusFoco.fechado:
      case StatusFoco.recusado:
        return SampleStatus.exported; // Usando 'exported' para visualização distinta
    }
  }

  void clearAllMapData() {
    _samplePoints = [];
    _currentAcao = null;
    if (_isFollowingUser) toggleFollowingUser();
    stopGoTo();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // --- Lógica de GPS e Navegação ---

  void toggleFollowingUser() {
    if (_isFollowingUser) {
      _positionStreamSubscription?.cancel();
      _isFollowingUser = false;
    } else {
      const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        _currentUserPosition = position;
        notifyListeners();
      });
      _isFollowingUser = true;
    }
    notifyListeners();
  }

  void startGoTo(SamplePoint target) {
    _goToTarget = target;
    if(!isFollowingUser) toggleFollowingUser(); // Ativa o GPS se não estiver ativo
    notifyListeners();
  }

  void stopGoTo() {
    _goToTarget = null;
    notifyListeners();
  }

  Future<void> launchNavigation(LatLng destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Não foi possível abrir o aplicativo de mapas.';
    }
  }

  Map<String, String> getGoToInfo() {
    if (!isGoToModeActive || _currentUserPosition == null) {
      return {'distance': '- m', 'bearing': '- °'};
    }
    const distance = Distance();
    final start = LatLng(_currentUserPosition!.latitude, _currentUserPosition!.longitude);
    final end = _goToTarget!.position;
    final distanceInMeters = distance.as(LengthUnit.Meter, start, end);
    final bearing = distance.bearing(start, end);
    return {
      'distance': '${distanceInMeters.toStringAsFixed(0)} m',
      'bearing': '${bearing.toStringAsFixed(0)}° ${_formatBearing(bearing)}'
    };
  }

  String _formatBearing(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return directions[((bearing % 360) / 45).round()];
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}