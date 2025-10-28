// lib/pages/planejamento/mapa_planejamento_page.dart (VERSÃO FINAL E CORRIGIDA)

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

// Imports da nova arquitetura
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/sample_point.dart';
import 'package:geo_forest_surveillance/providers/map_provider.dart';
import 'package:geo_forest_surveillance/pages/visitas/form_visita_page.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';

class MapaPlanejamentoPage extends StatefulWidget {
  const MapaPlanejamentoPage({super.key});

  @override
  State<MapaPlanejamentoPage> createState() => _MapaPlanejamentoPageState();
}

class _MapaPlanejamentoPageState extends State<MapaPlanejamentoPage> {
  final _mapController = MapController();
  // Repositórios necessários para buscar detalhes da campanha/ação
  final _campanhaRepository = CampanhaRepository();
  final _acaoRepository = AcaoRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      final bounds = mapProvider.bounds;
      if (bounds != null && bounds.northEast != null && bounds.southWest != null) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    if (mapProvider.isFollowingUser) mapProvider.toggleFollowingUser();
    if (mapProvider.isGoToModeActive) mapProvider.stopGoTo();
    super.dispose();
  }

  // A nova lógica de cor é baseada no status do SamplePoint (Pendente vs Visitado)
  Color _getMarkerColor(SampleStatus status) {
    switch (status) {
      case SampleStatus.completed:
        return Colors.green.shade700;
      case SampleStatus.untouched:
        return Colors.blueGrey;
      default:
        return Colors.orange;
    }
  }

  Future<void> _handleLocationButtonPressed() async {
    // TODO: Implementar a lógica de localização, se necessário, usando o MapProvider
    context.read<MapProvider>().toggleFollowingUser();
  }

  void _showMarkerOptions(BuildContext context, SamplePoint samplePoint) {
    final mapProvider = context.read<MapProvider>();
    final imovel = samplePoint.data['imovel'] as Imovel?;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            title: Text(imovel?.logradouro ?? 'Imóvel ID: ${samplePoint.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Lat: ${samplePoint.position.latitude.toStringAsFixed(5)}, Lon: ${samplePoint.position.longitude.toStringAsFixed(5)}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.navigation_outlined, color: Colors.blue),
            title: const Text('Navegar até o local'),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                await mapProvider.launchNavigation(samplePoint.position);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_outlined, color: Colors.green),
            title: const Text('Ir para (off-road)'),
            onTap: () {
              Navigator.pop(ctx);
              mapProvider.startGoTo(samplePoint);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoToInfoCard(MapProvider mapProvider) {
    if (!mapProvider.isGoToModeActive) return const SizedBox.shrink();
    final info = mapProvider.getGoToInfo();
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distância: ${info['distance']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Direção: ${info['bearing']}'),
                ],
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => mapProvider.stopGoTo())
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(MapProvider mapProvider) {
    final nomeAcao = mapProvider.currentAcao?.tipo ?? 'Planejamento';
    return AppBar(
      title: Text('Mapa: $nomeAcao'),
      actions: [
        IconButton(icon: const Icon(Icons.layers_outlined), onPressed: () => mapProvider.switchMapLayer(), tooltip: 'Mudar Camada'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final currentUserPosition = mapProvider.currentUserPosition;

    return Scaffold(
      appBar: _buildAppBar(mapProvider),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: LatLng(-15.7, -47.8), initialZoom: 4),
            children: [
              TileLayer(urlTemplate: mapProvider.currentTileUrl),
              PolygonLayer(polygons: mapProvider.polygons),
              MarkerLayer(
                markers: mapProvider.samplePoints.map((samplePoint) {
                  final color = _getMarkerColor(samplePoint.status);
                  final imovel = samplePoint.data['imovel'] as Imovel?;

                  return Marker(
                    width: 40.0,
                    height: 40.0,
                    point: samplePoint.position,
                    child: GestureDetector(
                      onTap: () async {
                        if (imovel == null) return;
                        
                        // Busca os detalhes da campanha e da ação para passar para o formulário de visita
                        final acao = mapProvider.currentAcao;
                        if (acao == null) return;
                        final campanha = await _campanhaRepository.getCampanhaById(acao.campanhaId);
                        if (!mounted || campanha == null) return;

                        final bool? foiSalvo = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormVisitaPage(
                              imovel: imovel,
                              campanha: campanha,
                              acao: acao,
                            ),
                          ),
                        );
                        // Se a visita foi salva, recarrega os dados do mapa para atualizar o status do ponto
                        if (foiSalvo == true && mounted) {
                          context.read<MapProvider>().loadDataForAcao();
                        }
                      },
                      onLongPress: () => _showMarkerOptions(context, samplePoint),
                      child: Tooltip(
                        message: imovel?.logradouro ?? "Imóvel ID ${imovel?.id}",
                        child: Container(
                          decoration: BoxDecoration(
                              color: color.withAlpha(230),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(128),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2))
                              ]),
                          child: Center(child: Text(samplePoint.id.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (currentUserPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(currentUserPosition.latitude, currentUserPosition.longitude),
                    child: const LocationMarker(),
                  ),
                ]),
            ],
          ),
          if (mapProvider.isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Carregando dados do mapa...", style: TextStyle(color: Colors.white)),
              ])),
            ),
          _buildGoToInfoCard(mapProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleLocationButtonPressed,
        tooltip: 'Minha Localização',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class LocationMarker extends StatefulWidget {
  const LocationMarker({super.key});
  @override
  State<LocationMarker> createState() => _LocationMarkerState();
}

class _LocationMarkerState extends State<LocationMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: false);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_animation),
          child: ScaleTransition(
            scale: _animation,
            child: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(102)),
            ),
          ),
        ),
        Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade700,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ],
          ),
        ),
      ],
    );
  }
}