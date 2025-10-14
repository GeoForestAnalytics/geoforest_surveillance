// lib/models/sample_point.dart

import 'package:latlong2/latlong.dart';

// Enum genérico para o status visual de um ponto no mapa
enum SampleStatus {
  untouched, // Ponto não visitado
  open,      // Vistoria em andamento
  completed, // Vistoria concluída
  exported,  // Dado já exportado
}

class SamplePoint {
  final int id;
  final LatLng position;
  final Map<String, dynamic> data; // Para guardar dados extras, como o ID do banco de dados
  SampleStatus status; 

  SamplePoint({
    required this.id,
    required this.position,
    Map<String, dynamic>? data,
    this.status = SampleStatus.untouched, 
  }) : data = data ?? {};
}