// lib/pages/importacao/import_page.dart (VERSÃO CORRIGIDA E FINAL)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
// Corrija para 'controllers' se a sua pasta estiver no plural
import 'package:geo_forest_surveillance/controller/import_controller.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCampanhaController = TextEditingController();
  final _orgaoController = TextEditingController();
  final _nomeAcaoController = TextEditingController();
  final _municipioIdController = TextEditingController();
  // =======================================================
  // >> CAMPOS ADICIONADOS AQUI <<
  // =======================================================
  final _municipioNomeController = TextEditingController();
  final _municipioUfController = TextEditingController();

  File? _selectedFile;

  @override
  void dispose() {
    _nomeCampanhaController.dispose();
    _orgaoController.dispose();
    _nomeAcaoController.dispose();
    _municipioIdController.dispose();
    // =======================================================
    // >> DISPOSE DOS NOVOS CONTROLLERS <<
    // =======================================================
    _municipioNomeController.dispose();
    _municipioUfController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['geojson', 'json'], // Aceita .json também
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhum arquivo selecionado ou caminho inválido.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ImportController(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar Nova Campanha')),
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
                    TextFormField(
                      controller: _nomeCampanhaController,
                      decoration: const InputDecoration(
                          labelText: 'Nome da Campanha',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.campaign_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _orgaoController,
                      decoration: const InputDecoration(
                          labelText: 'Órgão Responsável',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.corporate_fare_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomeAcaoController,
                      decoration: const InputDecoration(
                          labelText: 'Nome da Ação/Ciclo Padrão',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_walk_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _municipioIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'ID do Município (Código IBGE)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    // =======================================================
                    // >> NOVOS CAMPOS DE FORMULÁRIO ADICIONADOS AQUI <<
                    // =======================================================
                    TextFormField(
                      controller: _municipioNomeController,
                      decoration: const InputDecoration(
                          labelText: 'Nome do Município',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _municipioUfController,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                          labelText: 'UF do Município',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.public_outlined),
                          counterText: ""),
                      validator: (v) => v == null || v.trim().length != 2
                          ? 'Informe a sigla (2 letras).'
                          : null,
                    ),
                    // =======================================================
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile == null
                          ? 'Selecionar Arquivo GeoJSON'
                          : 'Arquivo: ${_selectedFile!.path.split(Platform.pathSeparator).last}'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    if (_selectedFile == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Nenhum arquivo selecionado.',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                      ),

                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() &&
                            _selectedFile != null) {
                          final bool sucesso =
                              await controller.processarImportacao(
                            geojsonFile: _selectedFile!,
                            nomeCampanha: _nomeCampanhaController.text.trim(),
                            orgao: _orgaoController.text.trim(),
                            nomeAcao: _nomeAcaoController.text.trim(),
                            municipioIdPadrao:
                                _municipioIdController.text.trim(),
                            // =======================================================
                            // >> NOVOS PARÂMETROS ENVIADOS PARA O CONTROLLER <<
                            // =======================================================
                            municipioNome: _municipioNomeController.text.trim(),
                            municipioUf: _municipioUfController.text
                                .trim()
                                .toUpperCase(),
                            tipoCampanha:
                                'dengue', // Default value, can be made configurable later
                          );

                          if (sucesso && mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Campanha e setores importados com sucesso!'),
                              backgroundColor: Colors.green,
                            ));
                            Navigator.pop(context,
                                true); // Retorna 'true' para a página anterior recarregar a lista
                          }
                        } else if (_selectedFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Por favor, selecione um arquivo GeoJSON.'),
                                backgroundColor: Colors.orange),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Importar e Criar Campanha'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16)),
                    ),

                    if (controller.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
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
