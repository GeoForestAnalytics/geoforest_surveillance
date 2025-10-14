// lib/pages/planejamento/mapa_planejamento_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/sample_point.dart';
import 'package:geo_forest_surveillance/providers/map_provider.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/pages/focos/form_foco_page.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart'; // Import necessário

class MapaPlanejamentoPage extends StatefulWidget {
  const MapaPlanejamentoPage({super.key});

  @override
  State<MapaPlanejamentoPage> createState() => _MapaPlanejamentoPageState();
}

class _MapaPlanejamentoPageState extends State<MapaPlanejamentoPage> with RouteAware {
  final _mapController = MapController();
  final FocoRepository _focoRepository = FocoRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registra a rota para ouvir quando a página volta a ser visível
    // MapProvider.routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    // MapProvider.routeObserver.unsubscribe(this);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    if (mapProvider.isFollowingUser) mapProvider.toggleFollowingUser();
    if (mapProvider.isGoToModeActive) mapProvider.stopGoTo();
    super.dispose();
  }

  // Converte o status genérico para o status específico de FocoDengue
  StatusFoco _getFocoStatusFromSample(SamplePoint sample) {
    // Tenta encontrar o status pelo nome. Se não encontrar, retorna um padrão.
    return StatusFoco.values.firstWhere(
      (e) => e.name == sample.status.name,
      orElse: () => StatusFoco.semFoco, 
    );
  }

  Color _getMarkerColor(StatusFoco status) {
    switch (status) {
      case StatusFoco.focoEliminado: case StatusFoco.tratado: return Colors.red.shade700;
      case StatusFoco.potencial: return Colors.orange.shade700;
      case StatusFoco.semFoco: return Colors.green;
      case StatusFoco.fechado: case StatusFoco.recusado: return Colors.grey.shade600;
    }
  }

  Future<void> _handleLocationButtonPressed() async {
    final provider = context.read<MapProvider>();
    // ... Lógica completa de GPS ... (igual ao GeoForest)
    // (Esta parte pode ser implementada em detalhes depois, por enquanto deixamos o aviso)
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionalidade de GPS a ser implementada.')));
  }

  void _showMarkerOptions(BuildContext context, SamplePoint samplePoint) {
    final mapProvider = context.read<MapProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            title: Text('Vistoria ID: ${samplePoint.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      bottom: 20, left: 20, right: 20,
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
        IconButton(icon: const Icon(Icons.file_upload_outlined), onPressed: () {/* TODO */}, tooltip: 'Importar Plano de Vistorias'),
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
              MarkerLayer(
                markers: mapProvider.samplePoints.map((samplePoint) {
                  final status = _getFocoStatusFromSample(samplePoint);
                  final color = _getMarkerColor(status);
                  
                  return Marker(
                    width: 40.0, height: 40.0, point: samplePoint.position,
                    child: GestureDetector(
                      onTap: () async {
                        final dbId = samplePoint.data['dbId'] as int?;
                        if (dbId == null) return;
                        
                        final foco = await _focoRepository.getFocoById(dbId);
                        if (foco == null || !mounted) return;

                        // TODO: Precisamos do objeto Bairro para navegar para o formulário.
                        // A forma mais fácil é buscar no MapProvider ou passar o ID.
                        // Por enquanto, vamos simular com dados dummy.
                        final bairroDummy = Bairro(id: foco.bairroId, acaoId: 0, municipioId: '', nome: 'Carregando...');

                        final bool? foiSalvo = await Navigator.push<bool>(context, MaterialPageRoute(
                          builder: (context) => FormFocoPage(
                            bairro: bairroDummy, 
                            campanhaId: foco.campanhaId, 
                            focoParaEditar: foco
                          ),
                        ));
                        if (foiSalvo == true && mounted) {
                           context.read<MapProvider>().loadPontosParaAcao();
                        }
                      },
                      onLongPress: () => _showMarkerOptions(context, samplePoint),
                      child: Tooltip(
                        message: "Vistoria ${samplePoint.id}",
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.9), 
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(2, 2))]
                          ),
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
                    width: 80.0, height: 80.0,
                    point: LatLng(currentUserPosition.latitude, currentUserPosition.longitude),
                    child: const LocationMarker(),
                  ),
                ]),
            ],
          ),
          if (mapProvider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
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


// Widget do marcador de localização do usuário (igual ao do GeoForest)
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4)),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))],
          ),
        ),
      ],
    );
  }
}