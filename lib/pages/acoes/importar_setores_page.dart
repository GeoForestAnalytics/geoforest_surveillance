// lib/pages/acoes/importar_setores_page.dart (VERSÃO SIMPLIFICADA)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geo_forest_surveillance/controller/import_controller.dart';

class ImportarSetoresPage extends StatefulWidget {
  final int acaoId;

  const ImportarSetoresPage({super.key, required this.acaoId});

  @override
  State<ImportarSetoresPage> createState() => _ImportarSetoresPageState();
}

class _ImportarSetoresPageState extends State<ImportarSetoresPage> {
  File? _selectedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['geojson', 'json'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ImportController(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar Setores via GeoJSON')),
        body: Consumer<ImportController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processando arquivo, aguarde...'),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.upload_file_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'Selecione o arquivo GeoJSON contendo os polígonos dos municípios e setores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile == null ? 'Selecionar Arquivo' : 'Arquivo: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: (_selectedFile == null) ? null : () async {
                        final bool sucesso = await controller.processarGeoJsonCompleto(
                          geojsonFile: _selectedFile!,
                          acaoId: widget.acaoId,
                        );

                        if (sucesso && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Dados importados com sucesso!'),
                            backgroundColor: Colors.green,
                          ));
                          Navigator.pop(context, true);
                        }
                      },
                      icon: const Icon(Icons.download_done_outlined),
                      label: const Text('Confirmar Importação'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    if (controller.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}