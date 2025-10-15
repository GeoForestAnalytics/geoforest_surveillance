// lib/pages/focos/form_foco_page.dart (VERSÃO CORRIGIDA COM TODAS AS FUNÇÕES)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';

import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart';
import 'package:geo_forest_surveillance/services/permission_service.dart';

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
  final _permissionService = PermissionService();
  final _picker = ImagePicker();
  bool _isSaving = false;
  
  // Controladores
  final _enderecoController = TextEditingController();
  final _obsController = TextEditingController();

  // Variáveis de estado
  double? _latitude;
  double? _longitude;
  TipoLocal _tipoLocal = TipoLocal.residencia;
  StatusFoco _statusFoco = StatusFoco.semFoco;
  
  bool _buscandoLocalizacao = false;
  String? _erroLocalizacao;
  Position? _posicaoAtualExibicao;

  final List<String> _opcoesRecipientes = [
    'Pneu', 'Vaso de Planta', 'Garrafa PET', 'Lixo Acumulado',
    'Caixa d\'água', 'Calha', 'Piscina', 'Laje', 'Outro'
  ];
  final Set<String> _recipientesSelecionados = {};
  List<String> _photoPaths = [];

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
      _recipientesSelecionados.addAll(foco.recipientes);
      _photoPaths = List.from(foco.photoPaths);
      
      if (_latitude != null && _longitude != null) {
        _posicaoAtualExibicao = Position(
            latitude: _latitude!, longitude: _longitude!,
            timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0
        );
      }
    } else {
      _obterLocalizacaoAtual(); 
    }
  }
  
  @override
  void dispose() {
    _enderecoController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final bool hasPermission = await _permissionService.requestStoragePermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissão de armazenamento/câmera negada.'), backgroundColor: Colors.red));
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1280);
    if (pickedFile == null || !mounted) return;

    try {
      await Gal.putImage(pickedFile.path);

      setState(() {
        _photoPaths.add(pickedFile.path);
      });
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto salva na galeria e anexada!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar foto: $e'), backgroundColor: Colors.red));
      }
    }
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
      recipientes: _recipientesSelecionados.toList(),
      photoPaths: _photoPaths,
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
  
  // ==========================================================
  // INÍCIO DAS FUNÇÕES QUE ESTAVAM FALTANDO
  // ==========================================================

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
        _posicaoAtualExibicao = position;
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

    } catch (e) {
      setState(() => _erroLocalizacao = e.toString());
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  String _getTextoTipoLocal(TipoLocal tipo) {
    switch (tipo) {
      case TipoLocal.residencia: return 'Residência';
      case TipoLocal.terrenoBaldio: return 'Terreno Baldio';
      case TipoLocal.comercio: return 'Comércio';
      case TipoLocal.pontoEstrategico: return 'Ponto Estratégico';
      case TipoLocal.outro: return 'Outro';
    }
  }

  String _getTextoStatusFoco(StatusFoco status) {
    switch (status) {
      case StatusFoco.focoEliminado: return 'Foco Eliminado';
      case StatusFoco.potencial: return 'Recipiente Potencial';
      case StatusFoco.tratado: return 'Tratado com Larvicida';
      case StatusFoco.recusado: return 'Visita Recusada';
      case StatusFoco.fechado: return 'Imóvel Fechado';
      case StatusFoco.semFoco: return 'Sem Foco Encontrado';
    }
  }

  // ==========================================================
  // FIM DAS FUNÇÕES QUE ESTAVAM FALTANDO
  // ==========================================================

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
              
              _buildColetorCoordenadas(),
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
                items: TipoLocal.values.map((tipo) => DropdownMenuItem(value: tipo, child: Text(_getTextoTipoLocal(tipo)))).toList(),
                onChanged: (v) { if (v != null) setState(() => _tipoLocal = v); },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StatusFoco>(
                value: _statusFoco,
                decoration: const InputDecoration(labelText: 'Resultado da Vistoria', border: OutlineInputBorder()),
                items: StatusFoco.values.map((status) => DropdownMenuItem(value: status, child: Text(_getTextoStatusFoco(status)))).toList(),
                onChanged: (v) { if (v != null) setState(() => _statusFoco = v); },
              ),
              const SizedBox(height: 16),

              _buildSelecaoRecipientes(),
              const SizedBox(height: 16),
              
              _buildPhotoSection(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _obsController,
                decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarFoco,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
                label: const Text('Salvar Vistoria'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColetorCoordenadas() {
    final latExibicao = _posicaoAtualExibicao?.latitude;
    final lonExibicao = _posicaoAtualExibicao?.longitude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Localização GPS', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                child: _buscandoLocalizacao
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Buscando...')])
                  : _erroLocalizacao != null
                    ? Text('Erro: $_erroLocalizacao', style: const TextStyle(color: Colors.red))
                    : (latExibicao == null)
                      ? const Text('Nenhuma localização obtida.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lat: ${latExibicao.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Lon: ${lonExibicao!.toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (_posicaoAtualExibicao != null && _posicaoAtualExibicao!.accuracy > 0)
                              Text('Precisão: ±${_posicaoAtualExibicao!.accuracy.toStringAsFixed(1)}m', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF00838F)), 
                onPressed: _buscandoLocalizacao ? null : _obterLocalizacaoAtual, 
                tooltip: 'Obter localização atual'
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelecaoRecipientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recipientes Encontrados', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _opcoesRecipientes.map((recipiente) {
              final isSelected = _recipientesSelecionados.contains(recipiente);
              return FilterChip(
                label: Text(recipiente),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _recipientesSelecionados.add(recipiente);
                    } else {
                      _recipientesSelecionados.remove(recipiente);
                    }
                  });
                },
                backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : null,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos da Vistoria', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              _photoPaths.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Nenhuma foto adicionada.')))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _photoPaths.length,
                      itemBuilder: (context, index) {
                        final photoPath = _photoPaths[index];
                        final file = File(photoPath);

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                                  ),
                            ),
                            Positioned(
                              top: -8, right: -8,
                              child: IconButton(
                                icon: const CircleAvatar(backgroundColor: Colors.white, radius: 12, child: Icon(Icons.close, color: Colors.red, size: 16)),
                                onPressed: () => setState(() => _photoPaths.removeAt(index)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Câmera'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeria'))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}