// lib/pages/gerente/gerente_map_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// Imports da nova arquitetura
import 'package:geo_forest_surveillance/providers/gerente_provider.dart';
// =======================================================
// >> IMPORT CORRIGIDO PARA O LOCAL DO ENUM <<
// =======================================================
import 'package:geo_forest_surveillance/models/visita_model.dart';


// Classe auxiliar para camadas do mapa
class MapLayer {
  final String name;
  final IconData icon;
  final TileLayer tileLayer;
  MapLayer({required this.name, required this.icon, required this.tileLayer});
}

class GerenteMapPage extends StatefulWidget {
  const GerenteMapPage({super.key});

  @override
  State<GerenteMapPage> createState() => _GerenteMapPageState();
}

class _GerenteMapPageState extends State<GerenteMapPage> {
  final MapController _mapController = MapController();
  
  static final List<MapLayer> _mapLayers = [
    MapLayer(name: 'Ruas', icon: Icons.map_outlined, tileLayer: TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')),
    MapLayer(name: 'Satélite', icon: Icons.satellite_alt_outlined, tileLayer: TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}')),
  ];
  
  late MapLayer _currentLayer;
  Position? _currentUserPosition;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Inicia o monitoramento de dados assim que a tela é construída
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GerenteProvider>().iniciarMonitoramento();
    });
    _currentLayer = _mapLayers[1];
  }

  // Função adaptada para ler o status de um formulário JSON de dengue
  StatusFoco _getStatusFromDadosFormulario(String? dadosJson) {
    if (dadosJson == null) return StatusFoco.semFoco;
    try {
      final data = jsonDecode(dadosJson);
      final statusString = data['statusFoco'];
      return StatusFoco.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => StatusFoco.semFoco,
      );
    } catch (e) {
      return StatusFoco.semFoco;
    }
  }

  Color _getMarkerColor(StatusFoco status) {
    switch (status) {
      case StatusFoco.focoEliminado:
      case StatusFoco.tratado:
        return Colors.red.shade700;
      case StatusFoco.potencial:
        return Colors.orange.shade700;
      case StatusFoco.semFoco:
        return Colors.green;
      case StatusFoco.fechado:
      case StatusFoco.recusado:
        return Colors.grey.shade600;
      // Adicionado um default para garantir que a função sempre retorne uma cor
      default:
        return Colors.blueGrey;
    }
  }

  void _switchMapLayer() {
    setState(() => _currentLayer = _mapLayers[(_mapLayers.indexOf(_currentLayer) + 1) % _mapLayers.length]);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Serviço de GPS desabilitado.';
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permissão negada.';
      }
      if (permission == LocationPermission.deniedForever) throw 'Permissão negada permanentemente.';
      
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentUserPosition = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao obter localização: $e')));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Geral de Visitas'),
        actions: [
          IconButton(icon: Icon(_currentLayer.icon), onPressed: _switchMapLayer, tooltip: 'Mudar Camada do Mapa'),
        ],
      ),
      body: Consumer<GerenteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final visitas = provider.visitasEnriquecidas;

          if (visitas.isEmpty) {
            return const Center(child: Text('Nenhuma visita sincronizada para exibir no mapa.'));
          }

          final markers = visitas
              .where((v) => v.imovel.latitude != 0.0 && v.imovel.longitude != 0.0) 
              .map<Marker>((visitaEnriquecida) {
            
            final imovel = visitaEnriquecida.imovel;
            final visita = visitaEnriquecida.visita;
            
            final status = _getStatusFromDadosFormulario(visita.dadosFormulario);
            final color = _getMarkerColor(status);

            return Marker(
              width: 35.0,
              height: 35.0,
              point: LatLng(imovel.latitude, imovel.longitude),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    duration: const Duration(seconds: 4),
                    content: Text(
                      'Endereço: ${imovel.logradouro}, ${imovel.numero ?? 'S/N'}\n'
                      'Agente: ${visita.nomeAgente}\n'
                      'Status (Dengue): ${status.name}',
                    ),
                  ));
                },
                child: Tooltip(
                  message: '${imovel.logradouro}, ${imovel.numero ?? 'S/N'}',
                  child: Icon(
                    Icons.location_pin,
                    color: color,
                    size: 35.0,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            );
          }).toList();
          
          if (_currentUserPosition != null) {
            markers.add(
              Marker(
                point: LatLng(_currentUserPosition!.latitude, _currentUserPosition!.longitude),
                width: 80, height: 80,
                child: const LocationMarker(),
              )
            );
          }

          return FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-15.7, -47.8),
              initialZoom: 4,
            ),
            children: [
              _currentLayer.tileLayer,
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLocating ? null : _getCurrentLocation,
        tooltip: 'Minha Localização',
        child: _isLocating ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.my_location),
      ),
    );
  }
}

// Widget auxiliar para o marcador de localização do usuário
class LocationMarker extends StatelessWidget {
  const LocationMarker({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 20.0,
        height: 20.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade700,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))],
        ),
      ),
    );
  }
}