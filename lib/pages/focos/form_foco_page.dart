// lib/pages/focos/form_foco_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart';

class FormFocoPage extends StatefulWidget {
  final Bairro bairro;
  final int campanhaId;
  final FocoDengue? focoParaEditar;

  const FormFocoPage({
    super.key,
    required this.bairro,
    required this.campanhaId,
    this.focoParaEditar,
  });

  bool get isEditing => focoParaEditar != null;

  @override
  State<FormFocoPage> createState() => _FormFocoPageState();
}

class _FormFocoPageState extends State<FormFocoPage> {
  final _formKey = GlobalKey<FormState>();
  final _focoRepository = FocoRepository();
  bool _isSaving = false;
  
  // Controladores
  final _enderecoController = TextEditingController();
  final _obsController = TextEditingController();

  // Variáveis de estado
  double? _latitude;
  double? _longitude;
  TipoLocal _tipoLocal = TipoLocal.residencia;
  StatusFoco _statusFoco = StatusFoco.semFoco;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final foco = widget.focoParaEditar!;
      _enderecoController.text = foco.endereco;
      _obsController.text = foco.observacao ?? '';
      _latitude = foco.latitude;
      _longitude = foco.longitude;
      _tipoLocal = foco.tipoLocal;
      _statusFoco = foco.statusFoco;
    } else {
      _obterCoordenadasIniciais();
    }
  }

  Future<void> _obterCoordenadasIniciais() async {
    // Lógica para pegar GPS (semelhante ao GeoForest)
    // ...
  }

  Future<void> _salvarFoco() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordenadas GPS são obrigatórias.')));
      return;
    }

    setState(() => _isSaving = true);
    
    final agente = context.read<TeamProvider>().lider ?? 'Agente não identificado';

    final foco = FocoDengue(
      id: widget.focoParaEditar?.id,
      uuid: widget.focoParaEditar?.uuid,
      bairroId: widget.bairro.id!,
      campanhaId: widget.campanhaId,
      endereco: _enderecoController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      dataVisita: DateTime.now(),
      tipoLocal: _tipoLocal,
      statusFoco: _statusFoco,
      observacao: _obsController.text.trim(),
      nomeAgente: agente,
    );

    try {
      await _focoRepository.saveFocoCompleto(foco);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vistoria salva com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Editar Vistoria' : 'Nova Vistoria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bairro/Setor: ${widget.bairro.nome}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço Completo', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O endereço é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipoLocal>(
                value: _tipoLocal,
                decoration: const InputDecoration(labelText: 'Tipo do Imóvel', border: OutlineInputBorder()),
                items: TipoLocal.values.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo.name))).toList(),
                onChanged: (v) { if (v != null) setState(() => _tipoLocal = v); },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StatusFoco>(
                value: _statusFoco,
                decoration: const InputDecoration(labelText: 'Resultado da Vistoria', border: OutlineInputBorder()),
                items: StatusFoco.values.map((status) => DropdownMenuItem(value: status, child: Text(status.name))).toList(),
                onChanged: (v) { if (v != null) setState(() => _statusFoco = v); },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obsController,
                decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarFoco,
                icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                label: const Text('Salvar Vistoria'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}