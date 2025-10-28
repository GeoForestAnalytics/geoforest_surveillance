// Arquivo: lib/pages/importacao/importar_postos_page.dart (NOVO ARQUIVO)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geo_forest_surveillance/controller/import_controller.dart';

class ImportarPostosPage extends StatefulWidget {
  const ImportarPostosPage({super.key});

  @override
  State<ImportarPostosPage> createState() => _ImportarPostosPageState();
}

class _ImportarPostosPageState extends State<ImportarPostosPage> {
  File? _selectedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['geojson', 'json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum arquivo selecionado ou caminho inválido.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ImportController(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar Coordenadas dos Postos')),
        body: Consumer<ImportController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Atualizando postos de saúde...'),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.add_location_alt_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  const Text(
                    'Selecione o arquivo GeoJSON contendo os pontos de localização dos Postos de Saúde. O sistema irá atualizar os postos existentes com as novas coordenadas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_selectedFile == null ? 'Selecionar Arquivo de Pontos' : 'Arquivo: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_selectedFile == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Nenhum arquivo selecionado.',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_selectedFile != null) {
                        final bool sucesso = await controller.processarImportacaoDePontos(
                          geojsonFile: _selectedFile!,
                        );

                        if (sucesso && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Coordenadas dos postos importadas com sucesso!'),
                            backgroundColor: Colors.green,
                          ));
                          Navigator.pop(context, true); // Retorna true para indicar sucesso
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, selecione um arquivo GeoJSON de pontos.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar Coordenadas'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
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
                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}