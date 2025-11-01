// Arquivo: lib/pages/acoes/importar_setores_page.dart (NOVO ARQUIVO)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geo_forest_surveillance/controller/import_controller.dart';

class ImportarSetoresPage extends StatefulWidget {
  final int acaoId; // Recebe o ID da ação para associar os dados

  const ImportarSetoresPage({super.key, required this.acaoId});

  @override
  State<ImportarSetoresPage> createState() => _ImportarSetoresPageState();
}

class _ImportarSetoresPageState extends State<ImportarSetoresPage> {
  final _formKey = GlobalKey<FormState>();
  final _municipioIdController = TextEditingController();
  final _municipioNomeController = TextEditingController();
  final _municipioUfController = TextEditingController();

  File? _selectedFile;

  @override
  void dispose() {
    _municipioIdController.dispose();
    _municipioNomeController.dispose();
    _municipioUfController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['geojson', 'json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ImportController(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar Município e Setores')),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Preencha os dados do município e selecione o arquivo GeoJSON contendo os polígonos dos setores.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _municipioIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'ID do Município (Código IBGE)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_outlined)),
                      validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _municipioNomeController,
                      decoration: const InputDecoration(
                          labelText: 'Nome do Município',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city_outlined)),
                      validator: (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _municipioUfController,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          labelText: 'UF (Ex: SP)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.public_outlined),
                          counterText: ""),
                      validator: (v) => v == null || v.trim().length != 2 ? 'Informe a sigla (2 letras).' : null,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile == null ? 'Selecionar Arquivo GeoJSON' : 'Arquivo: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() && _selectedFile != null) {
                          final bool sucesso = await controller.processarImportacaoDeSetores(
                            geojsonFile: _selectedFile!,
                            acaoId: widget.acaoId,
                            municipioId: _municipioIdController.text.trim(),
                            municipioNome: _municipioNomeController.text.trim(),
                            municipioUf: _municipioUfController.text.trim().toUpperCase(),
                          );

                          if (sucesso && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Setores importados com sucesso!'),
                              backgroundColor: Colors.green,
                            ));
                            Navigator.pop(context, true); // Retorna true para a página anterior recarregar
                          }
                        } else if (_selectedFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, selecione um arquivo GeoJSON.'), backgroundColor: Colors.orange),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Importar Setores'),
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