// lib/pages/gerente/gerente_map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart'; // <-- MUDOU DE PARCELA PARA FOCO
import 'package:geo_forest_surveillance/providers/gerente_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// ... (A classe auxiliar MapLayer permanece a mesma)

class GerenteMapPage extends StatefulWidget {
  const GerenteMapPage({super.key});

  @override
  State<GerenteMapPage> createState() => _GerenteMapPageState();
}

class _GerenteMapPageState extends State<GerenteMapPage> {
  final MapController _mapController = MapController();
  // ... (outras variáveis de estado permanecem as mesmas)

  // <<< FUNÇÃO DE COR ATUALIZADA PARA O STATUS DO FOCO >>>
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
    }
  }

  // ... (funções de _centerMapOnMarkers, _switchMapLayer, _getCurrentLocation permanecem as mesmas)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Geral de Focos'),
        // ... (ações do AppBar permanecem as mesmas)
      ),
      body: Consumer<GerenteProvider>(
        builder: (context, provider, child) {
          // <<< CONSUMINDO A LISTA DE FOCOS DO PROVIDER >>>
          // Você precisará criar este getter 'focosFiltrados' no seu GerenteProvider
          final focos = provider.focosFiltrados; 

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (focos.isEmpty) {
            return const Center(child: Text('Nenhum foco sincronizado para exibir no mapa.'));
          }

          final markers = focos
              .map<Marker>((foco) {
            return Marker(
              width: 35.0,
              height: 35.0,
              point: LatLng(foco.latitude, foco.longitude),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'Bairro: ${foco.bairroNome ?? 'N/A'}\n' // Você precisará adicionar 'bairroNome' ao seu modelo
                      'Endereço: ${foco.endereco}\n'
                      'Status: ${foco.statusFoco.name}',
                    ),
                  ));
                },
                child: Icon(
                  Icons.location_pin,
                  color: _getMarkerColor(foco.statusFoco),
                  size: 35.0,
                ),
              ),
            );
          }).toList();
          
          // ... (o resto da lógica do build do mapa permanece a mesma)

          return FlutterMap(
            // ...
            children: [
              // ...
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
      // ... (FloatingActionButton permanece o mesmo)
    );
  }
}
// ... (Widget LocationMarker permanece o mesmo)