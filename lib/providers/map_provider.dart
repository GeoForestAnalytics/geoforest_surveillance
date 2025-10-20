// lib/providers/map_provider.dart (VERSÃO CORRIGIDA FINAL)

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/sample_point.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';

enum MapLayerType { ruas, satelite }

class MapProvider with ChangeNotifier {
  final _focoRepository = FocoRepository();
  final _bairroRepository = BairroRepository();

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
    // =======================================================
    // >> CORREÇÃO 1: INICIALIZAÇÃO DO BOUNDS REMOVIDA <<
    // A variável _bounds será criada apenas se houver pontos.
    // =======================================================
    _bounds = null;

    final bairros = await _bairroRepository.getTodosBairros();
    final bairrosDaAcao = bairros.where((b) => b.acaoId == _currentAcao!.id).toList();
    final List<LatLng> allPoints = [];

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
              color: Colors.primaries[Random().nextInt(Colors.primaries.length)].withAlpha(102), // 'withOpacity' obsoleto
              borderColor: Colors.black,
              borderStrokeWidth: 2,
              // =======================================================
              // >> CORREÇÃO 2: PARÂMETRO 'isFilled' REMOVIDO <<
              // =======================================================
            ));
          }
        } catch (e) {
          debugPrint("Erro ao decodificar geometria do bairro ${bairro.id}: $e");
        }
      }
    }

    final focos = await _focoRepository.getUnsyncedFocos();
    _samplePoints = focos.map((foco) {
      final point = LatLng(foco.latitude, foco.longitude);
      allPoints.add(point);
      return SamplePoint(
        id: foco.id ?? 0,
        position: point,
        status: _getSampleStatusFromFoco(foco),
        data: {'dbId': foco.id},
      );
    }).toList();

    if (allPoints.isNotEmpty) {
      _bounds = LatLngBounds.fromPoints(allPoints);
    }

    _setLoading(false);
  }

  SampleStatus _getSampleStatusFromFoco(FocoDengue foco) {
    switch (foco.statusFoco) {
      case StatusFoco.focoEliminado:
      case StatusFoco.tratado:
        return SampleStatus.completed;
      case StatusFoco.semFoco:
        return SampleStatus.completed;
      case StatusFoco.potencial:
        return SampleStatus.open;
      case StatusFoco.fechado:
      case StatusFoco.recusado:
        return SampleStatus.exported;
    }
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