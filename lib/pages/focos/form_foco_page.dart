// lib/pages/focos/form_foco_page.dart (COM FUNCIONALIDADE GPS)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; // <<< 1. IMPORT ADICIONADO

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

  // <<< 2. NOVAS VARIÁVEIS DE ESTADO PARA O GPS >>>
  bool _buscandoLocalizacao = false;
  String? _erroLocalizacao;
  Position? _posicaoAtualExibicao;

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
      // Se já estamos editando, cria um objeto Position para exibição
      if (_latitude != null && _longitude != null) {
        _posicaoAtualExibicao = Position(
            latitude: _latitude!, longitude: _longitude!,
            timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0
        );
      }
    } else {
      // Tenta obter as coordenadas assim que a tela abre
      _obterLocalizacaoAtual(); 
    }
  }

  // <<< 3. FUNÇÃO DE GPS COMPLETA >>>
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

  // A função de salvar permanece a mesma, já que ela depende de _latitude e _longitude
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

  // <<< 4. FUNÇÕES PARA TRADUZIR OS ENUMS PARA PORTUGUÊS >>>
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
              
              // <<< 5. WIDGET DO GPS ADICIONADO AO FORMULÁRIO >>>
              _buildColetorCoordenadas(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço Completo', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O endereço é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              
              // Dropdowns agora usam os textos traduzidos
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

  // <<< 6. WIDGET PARA A INTERFACE DO GPS >>>
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
}