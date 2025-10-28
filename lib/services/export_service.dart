// lib/services/export_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Imports da nova arquitetura
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/imovel_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';

// Imports legados
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';

import 'package:geo_forest_surveillance/services/permission_service.dart';
import 'package:geo_forest_surveillance/widgets/progress_dialog.dart';

// Payload para a nova função de exportação em background
class _CsvVisitaPayload {
  final List<Map<String, dynamic>> visitasCompletas;
  _CsvVisitaPayload({ required this.visitasCompletas });
}

// Nova função que roda em um isolate para gerar o CSV de visitas
Future<String> _generateCsvVisitaDataInIsolate(_CsvVisitaPayload payload) async {
  if (payload.visitasCompletas.isEmpty) return '';

  List<List<dynamic>> rows = [];

  // --- Geração de Cabeçalho Dinâmico ---
  final List<String> baseHeaders = [
    'visita_id', 'visita_uuid', 'data_visita', 'agente', 'responsavel_atendimento', 'observacoes',
    'imovel_id', 'imovel_uuid', 'logradouro', 'numero', 'complemento', 'latitude', 'longitude', 'tipo_imovel', 'qtd_moradores',
    'campanha_id', 'nome_campanha', 'tipo_campanha'
  ];
  
  // Descobre todas as chaves possíveis dos formulários dinâmicos
  final Set<String> dynamicHeaders = {};
  for (var visita in payload.visitasCompletas) {
    if (visita['dados_formulario'] != null) {
      try {
        final Map<String, dynamic> formData = jsonDecode(visita['dados_formulario']);
        final tipoCampanha = visita['tipo_campanha'] ?? 'geral';
        for (var key in formData.keys) {
          dynamicHeaders.add('${tipoCampanha}_$key');
        }
      } catch (_) {}
    }
  }

  final List<String> allHeaders = [...baseHeaders, ...dynamicHeaders.toList()..sort()];
  rows.add(allHeaders);

  // --- Geração das Linhas de Dados ---
  for (var visita in payload.visitasCompletas) {
    final Map<String, dynamic> rowMap = {};
    
    // Preenche dados base
    rowMap['visita_id'] = visita['id'];
    rowMap['visita_uuid'] = visita['uuid'];
    rowMap['data_visita'] = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(visita['dataVisita']));
    rowMap['agente'] = visita['nomeAgente'];
    rowMap['responsavel_atendimento'] = visita['nomeResponsavelAtendimento'];
    rowMap['observacoes'] = visita['observacao'];
    rowMap['imovel_id'] = visita['imovel_id'];
    rowMap['imovel_uuid'] = visita['imovel_uuid'];
    rowMap['logradouro'] = visita['logradouro'];
    rowMap['numero'] = visita['numero'];
    rowMap['complemento'] = visita['complemento'];
    rowMap['latitude'] = visita['latitude'].toString().replaceAll('.', ',');
    rowMap['longitude'] = visita['longitude'].toString().replaceAll('.', ',');
    rowMap['tipo_imovel'] = visita['tipoImovel'];
    rowMap['qtd_moradores'] = visita['quantidadeMoradores'];
    rowMap['campanha_id'] = visita['campanha_id'];
    rowMap['nome_campanha'] = visita['nome_campanha'];
    rowMap['tipo_campanha'] = visita['tipo_campanha'];

    // Preenche dados dinâmicos
    if (visita['dados_formulario'] != null) {
      try {
        final Map<String, dynamic> formData = jsonDecode(visita['dados_formulario']);
        final tipoCampanha = visita['tipo_campanha'] ?? 'geral';
        formData.forEach((key, value) {
          final headerKey = '${tipoCampanha}_$key';
          rowMap[headerKey] = value is List ? value.join('; ') : value;
        });
      } catch (_) {}
    }

    // Monta a linha na ordem correta dos cabeçalhos
    final List<dynamic> row = allHeaders.map((header) => rowMap[header] ?? '').toList();
    rows.add(row);
  }
  
  return const ListToCsvConverter().convert(rows, fieldDelimiter: ';');
}


class ExportService {
  final _permissionService = PermissionService();
  // Repositórios novos e legados
  final _visitaRepository = VisitaRepository();
  final _imovelRepository = ImovelRepository();
  final _campanhaRepository = CampanhaRepository();
  final _focoRepository = FocoRepository();

  /// Exporta todos os dados da nova arquitetura (Visitas e Imóveis) para um arquivo CSV.
  Future<void> exportarVisitasCsv(BuildContext context) async {
    try {
      final PermissionStatus status = await _permissionService.requestStoragePermission();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permissão de armazenamento negada.'), backgroundColor: Colors.orange,
          ));
        }
        return;
      }
      
      ProgressDialog.show(context, 'Buscando dados locais...');
      
      // Busca todos os dados necessários
      final List<Visita> visitas = await _visitaRepository.getVisitasDaCampanha(0); // Busca todas
      final List<Imovel> imoveis = await _imovelRepository.getTodosImoveis();
      final List<Campanha> campanhas = await _campanhaRepository.getTodasAsCampanhasParaGerente();
      
      if (visitas.isEmpty) {
        if (context.mounted) {
          ProgressDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma visita encontrada para exportar.'), backgroundColor: Colors.orange));
        }
        return;
      }

      ProgressDialog.hide(context);
      ProgressDialog.show(context, 'Preparando ${visitas.length} registros...');

      // "Join" dos dados em Dart
      final imoveisMap = {for (var i in imoveis) i.id: i};
      final campanhasMap = {for (var c in campanhas) c.id: c};
      
      final List<Map<String, dynamic>> visitasCompletas = visitas.map((visita) {
        final imovel = imoveisMap[visita.imovelId];
        final campanha = campanhasMap[visita.campanhaId];
        return {
          ...visita.toMap(),
          'imovel_id': imovel?.id,
          'imovel_uuid': imovel?.uuid,
          'logradouro': imovel?.logradouro,
          'numero': imovel?.numero,
          'complemento': imovel?.complemento,
          'latitude': imovel?.latitude,
          'longitude': imovel?.longitude,
          'tipoImovel': imovel?.tipoImovel,
          'quantidadeMoradores': imovel?.quantidadeMoradores,
          'campanha_id': campanha?.id,
          'nome_campanha': campanha?.nome,
          'tipo_campanha': campanha?.tipoCampanha,
        };
      }).toList();

      final payload = _CsvVisitaPayload(visitasCompletas: visitasCompletas);
      final String csvData = await compute(_generateCsvVisitaDataInIsolate, payload);
      
      final fName = 'exportacao_visitas_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.csv';
      
      await _salvarECompartilharCsv(context, csvData, fName, 'Exportação de Visitas - Geo Dengue Monitor');

    } catch (e, s) {
      debugPrint('Erro ao exportar visitas: $e\n$s');
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao exportar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(context.mounted && ModalRoute.of(context)!.isCurrent) ProgressDialog.hide(context);
    }
  }

  /// (LEGADO) Exporta dados da tabela antiga de focos.
  Future<void> exportarFocosCsv(BuildContext context) async {
    // Esta função permanece a mesma para compatibilidade com dados antigos.
    // ... (código da função exportarFocosCsv original) ...
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

// --- Implementação da Função Legada (para referência) ---

class _CsvFocoPayload {
  final List<Map<String, dynamic>> focosMap;
  _CsvFocoPayload({ required this.focosMap });
}

Future<String> _generateCsvFocoDataInIsolate(_CsvFocoPayload payload) async {
  List<List<dynamic>> rows = [];
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