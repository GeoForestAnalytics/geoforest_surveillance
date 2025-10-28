// Arquivo: lib/pages/cadastro/form_imovel_page.dart (NOVO ARQUIVO)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/data/repositories/imovel_repository.dart';

class FormImovelPage extends StatefulWidget {
  final int? bairroId; // Opcional, se o cadastro for feito dentro de um setor
  final Imovel? imovelParaEditar;

  const FormImovelPage({
    super.key,
    this.bairroId,
    this.imovelParaEditar,
  });

  bool get isEditing => imovelParaEditar != null;

  @override
  State<FormImovelPage> createState() => _FormImovelPageState();
}

class _FormImovelPageState extends State<FormImovelPage> {
  final _formKey = GlobalKey<FormState>();
  final _imovelRepository = ImovelRepository();
  bool _isSaving = false;

  // Controladores
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _cepController = TextEditingController();
  final _qtdMoradoresController = TextEditingController();

  // Variáveis de estado
  double? _latitude;
  double? _longitude;
  String? _tipoImovelSelecionado;
  
  bool _buscandoLocalizacao = false;
  String? _erroLocalizacao;
  
  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final imovel = widget.imovelParaEditar!;
      _logradouroController.text = imovel.logradouro;
      _numeroController.text = imovel.numero ?? '';
      _complementoController.text = imovel.complemento ?? '';
      _cepController.text = imovel.cep ?? '';
      _qtdMoradoresController.text = imovel.quantidadeMoradores?.toString() ?? '';
      _latitude = imovel.latitude;
      _longitude = imovel.longitude;
      _tipoImovelSelecionado = imovel.tipoImovel;
    } else {
      _obterLocalizacaoAtual();
    }
  }

  @override
  void dispose() {
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _cepController.dispose();
    _qtdMoradoresController.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacaoAtual() async {
    setState(() { _buscandoLocalizacao = true; _erroLocalizacao = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Serviço de GPS está desabilitado.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permissão de localização negada.';
      }
      if (permission == LocationPermission.deniedForever) throw 'Permissão negada permanentemente. Verifique as configurações do app.';

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

    } catch (e) {
      setState(() => _erroLocalizacao = e.toString());
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  Future<void> _salvarImovel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As coordenadas GPS são obrigatórias para o cadastro.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final imovel = Imovel(
      id: widget.imovelParaEditar?.id,
      uuid: widget.imovelParaEditar?.uuid ?? const Uuid().v4(),
      bairroId: widget.bairroId,
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      cep: _cepController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      tipoImovel: _tipoImovelSelecionado,
      quantidadeMoradores: int.tryParse(_qtdMoradoresController.text),
      dataCadastro: widget.isEditing ? widget.imovelParaEditar!.dataCadastro : DateTime.now(),
    );

    try {
      if (widget.isEditing) {
        await _imovelRepository.updateImovel(imovel);
      } else {
        await _imovelRepository.insertImovel(imovel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imóvel ${widget.isEditing ? 'atualizado' : 'cadastrado'} com sucesso!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar imóvel: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Imóvel' : 'Novo Cadastro de Imóvel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Localização'),
              _buildCoordenadasCard(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logradouroController,
                decoration: const InputDecoration(labelText: 'Endereço (Rua/Avenida)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O endereço é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _numeroController,
                      decoration: const InputDecoration(labelText: 'Nº', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _complementoController,
                      decoration: const InputDecoration(labelText: 'Complemento', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cepController,
                decoration: const InputDecoration(labelText: 'CEP', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Dados Demográficos'),
              
              DropdownButtonFormField<String>(
                value: _tipoImovelSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo do Imóvel', border: OutlineInputBorder()),
                items: ['Residência', 'Comércio', 'Terreno Baldio', 'Ponto Estratégico', 'Outro']
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoImovelSelecionado = v),
                validator: (v) => v == null ? 'Selecione um tipo.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtdMoradoresController,
                decoration: const InputDecoration(labelText: 'Quantidade de Moradores', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              // Aqui você pode adicionar o campo de Renda Familiar e outros que desejar
              
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarImovel,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(widget.isEditing ? 'Atualizar Cadastro' : 'Salvar Cadastro'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCoordenadasCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: _buscandoLocalizacao
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Buscando...')])
                : _erroLocalizacao != null
                  ? Text('Erro: $_erroLocalizacao', style: const TextStyle(color: Colors.red))
                  : (_latitude == null)
                    ? const Text('Nenhuma localização obtida.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lat: ${_latitude!.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Lon: ${_longitude!.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
            ),
            IconButton(
              icon: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary), 
              onPressed: _buscandoLocalizacao ? null : _obterLocalizacaoAtual, 
              tooltip: 'Obter localização atual'
            ),
          ],
        ),
      ),
    );
  }
}