// lib/providers/map_provider.dart (VERSÃO CORRIGIDA FINAL)

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// Imports da nova arquitetura
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/sample_point.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/imovel_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';

enum MapLayerType { ruas, satelite }

class MapProvider with ChangeNotifier {
  // Repositórios da nova arquitetura
  final _bairroRepository = BairroRepository();
  final _imovelRepository = ImovelRepository();
  final _visitaRepository = VisitaRepository();

  List<SamplePoint> _samplePoints = [];
  List<Polygon> _polygons = [];
  bool _isLoading = false;
  Acao? _currentAcao;
  MapLayerType _currentLayer = MapLayerType.satelite;
  LatLngBounds? _bounds;

  Position? _currentUserPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFollowingUser = false;
  SamplePoint? _goToTarget;

  List<SamplePoint> get samplePoints => _samplePoints;
  List<Polygon> get polygons => _polygons;
  bool get isLoading => _isLoading;
  Acao? get currentAcao => _currentAcao;
  MapLayerType get currentLayer => _currentLayer;
  Position? get currentUserPosition => _currentUserPosition;
  bool get isFollowingUser => _isFollowingUser;
  SamplePoint? get goToTarget => _goToTarget;
  bool get isGoToModeActive => _goToTarget != null;
  LatLngBounds? get bounds => _bounds;

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

  Future<void> loadDataForAcao() async {
    if (_currentAcao == null) return;
    _setLoading(true);
    _samplePoints.clear();
    _polygons.clear();
    _bounds = null;

    final List<LatLng> allPoints = [];

    // 1. Carregar polígonos dos bairros (setores) da ação
    final bairrosDaAcao = await _bairroRepository.getBairrosDoMunicipio('', _currentAcao!.id!); // Assumindo que o repositório pode lidar com municipioId vazio
    
    for (var bairro in bairrosDaAcao) {
      if (bairro.geometria != null && bairro.geometria!.isNotEmpty) {
        try {
          final List<LatLng> points = [];
          final decodedGeometry = jsonDecode(bairro.geometria!);
          final coordinates = decodedGeometry['coordinates'][0] as List;
          for (var point in coordinates) {
            if (point is List && point.length >= 2) {
              final latLng = LatLng(point[1].toDouble(), point[0].toDouble());
              points.add(latLng);
              allPoints.add(latLng);
            }
          }
          if (points.isNotEmpty) {
            _polygons.add(Polygon(
              points: points,
              color: Colors.primaries[Random().nextInt(Colors.primaries.length)].withAlpha(102),
              borderColor: Colors.black,
              borderStrokeWidth: 2,
            ));
          }
        } catch (e) {
          debugPrint("Erro ao decodificar geometria do bairro ${bairro.id}: $e");
        }
      }
    }

    // 2. Carregar todos os imóveis pertencentes a esses bairros
    List<Imovel> imoveisDaAcao = [];
    for (var bairro in bairrosDaAcao) {
      if (bairro.id != null) {
        final imoveisDoBairro = await _imovelRepository.getImoveisDoBairro(bairro.id!);
        imoveisDaAcao.addAll(imoveisDoBairro);
      }
    }

    // 3. Verificar quais imóveis já foram visitados NESTA campanha/ação
    final visitasDaAcao = await _visitaRepository.getVisitasDaCampanha(_currentAcao!.campanhaId);
    final visitedImovelIds = visitasDaAcao.map((v) => v.imovelId).toSet();

    // 4. Mapear imóveis para SamplePoints, definindo seu status (visitado ou pendente)
    _samplePoints = imoveisDaAcao.map((imovel) {
      final point = LatLng(imovel.latitude, imovel.longitude);
      allPoints.add(point);
      
      final bool foiVisitado = visitedImovelIds.contains(imovel.id);

      return SamplePoint(
        id: imovel.id ?? 0,
        position: point,
        status: foiVisitado ? SampleStatus.completed : SampleStatus.untouched,
        data: {'imovel': imovel}, // Armazena o objeto Imovel completo
      );
    }).toList();

    if (allPoints.isNotEmpty) {
      _bounds = LatLngBounds.fromPoints(allPoints);
    }

    _setLoading(false);
  }

  void clearAllMapData() {
    _samplePoints = [];
    _polygons = [];
    _currentAcao = null;
    if (_isFollowingUser) toggleFollowingUser();
    stopGoTo();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

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
    if (!isFollowingUser) toggleFollowingUser();
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