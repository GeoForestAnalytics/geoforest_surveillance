// lib/services/export_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // <<< IMPORT NECESSÁRIO

import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/services/permission_service.dart';
import 'package:geo_forest_surveillance/widgets/progress_dialog.dart';

// NOTA DE EVOLUÇÃO: Este serviço atualmente exporta dados do modelo antigo (Focos de Dengue).
// Em um próximo passo, criaremos novas funções aqui para exportar os dados das
// novas tabelas 'imoveis' e 'visitas'.

// Classe de payload para passar dados para o isolate
class _CsvFocoPayload {
  final List<Map<String, dynamic>> focosMap;
  // Adicione outros dados que o isolate possa precisar, como nome do agente, etc.

  _CsvFocoPayload({ required this.focosMap });
}

// Função que roda em um isolate para não travar a UI
Future<String> _generateCsvFocoDataInIsolate(_CsvFocoPayload payload) async {
  List<List<dynamic>> rows = [];
  
  // Cabeçalho do CSV
  rows.add([
    'ID', 'UUID', 'Bairro_ID', 'Campanha_ID', 'Endereço', 'Latitude', 'Longitude',
    'Data_Visita', 'Tipo_Local', 'Status_Foco', 'Recipientes', 'Amostras_Coletadas',
    'Tratamento', 'Observacao', 'Agente_Responsavel'
  ]);

  for (var focoMap in payload.focosMap) {
    final foco = FocoDengue.fromMap(focoMap);
    rows.add([
      foco.id, foco.uuid, foco.bairroId, foco.campanhaId, foco.endereco,
      foco.latitude.toString().replaceAll('.', ','), foco.longitude.toString().replaceAll('.', ','),
      DateFormat('dd/MM/yyyy HH:mm').format(foco.dataVisita),
      foco.tipoLocal.name, foco.statusFoco.name, foco.recipientes.join('; '),
      foco.amostrasColetadas, foco.tratamentoRealizado, foco.observacao, foco.nomeAgente
    ]);
  }
  
  return const ListToCsvConverter().convert(rows, fieldDelimiter: ';');
}


class ExportService {
  final _focoRepository = FocoRepository();
  final _permissionService = PermissionService();

  Future<void> exportarFocosCsv(BuildContext context) async {
    try {
      // =======================================================
      // >> CORREÇÃO APLICADA AQUI <<
      // Verificamos a propriedade .isGranted do PermissionStatus retornado.
      // =======================================================
      final PermissionStatus status = await _permissionService.requestStoragePermission();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permissão de armazenamento negada. Exportação cancelada.'),
            backgroundColor: Colors.orange,
          ));
        }
        return;
      }
      
      ProgressDialog.show(context, 'Buscando e preparando dados...');
      
      // Aqui, estamos exportando TODOS os focos. Você pode adaptar para usar filtros.
      final List<FocoDengue> focos = await _focoRepository.getUnsyncedFocos(); // Exemplo: exportar apenas os não sincronizados
      
      if (focos.isEmpty) {
        if (context.mounted) {
          ProgressDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum foco novo para exportar.'), backgroundColor: Colors.orange));
        }
        return;
      }

      final payload = _CsvFocoPayload(focosMap: focos.map((f) => f.toMap()).toList());
      final String csvData = await compute(_generateCsvFocoDataInIsolate, payload);
      
      final fName = 'exportacao_focos_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.csv';
      
      await _salvarECompartilharCsv(context, csvData, fName, 'Exportação de Focos - Geo Dengue');

      // Marca os focos como sincronizados/exportados após o compartilhamento
      for (final foco in focos) {
        await _focoRepository.markFocoAsSynced(foco.uuid);
      }

    } catch (e, s) {
      debugPrint('Erro ao exportar focos: $e\n$s');
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao exportar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(context.mounted) ProgressDialog.hide(context);
    }
  }

  // Funções auxiliares de salvamento e compartilhamento
  Future<String> _salvarEObterCaminho(String fileContent, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final bom = [0xEF, 0xBB, 0xBF]; 
    final bytes = utf8.encode(fileContent);
    await File(path).writeAsBytes([...bom, ...bytes]);
    return path;
  }
  
  Future<void> _salvarECompartilharCsv(BuildContext context, String csvData, String fileName, String subject) async {
    final path = await _salvarEObterCaminho(csvData, fileName);
    if (context.mounted) {
      ProgressDialog.hide(context);
      await Share.shareXFiles([XFile(path, name: fileName)], subject: subject);
    }
  }
}