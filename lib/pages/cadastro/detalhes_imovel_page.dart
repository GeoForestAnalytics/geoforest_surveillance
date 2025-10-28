// Arquivo: lib/pages/cadastro/detalhes_imovel_page.dart (NOVO ARQUIVO)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/data/repositories/imovel_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/pages/cadastro/form_imovel_page.dart';

class DetalhesImovelPage extends StatefulWidget {
  final int imovelId;

  const DetalhesImovelPage({super.key, required this.imovelId});

  @override
  State<DetalhesImovelPage> createState() => _DetalhesImovelPageState();
}

class _DetalhesImovelPageState extends State<DetalhesImovelPage> {
  final _imovelRepository = ImovelRepository();
  final _visitaRepository = VisitaRepository();
  final _campanhaRepository = CampanhaRepository();
  final _acaoRepository = AcaoRepository();

  late Future<Imovel?> _imovelFuture;
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _imovelFuture = _imovelRepository.getImovelById(widget.imovelId);
      // Carrega visitas, campanhas e ações de uma vez para construir o histórico
      _historyFuture = Future.wait([
        _visitaRepository.getVisitasDoImovel(widget.imovelId),
        _campanhaRepository.getTodasAsCampanhasParaGerente(),
        _acaoRepository.getTodasAcoes(),
      ]);
    });
  }

  Future<void> _navegarParaEditarImovel(Imovel imovel) async {
    final bool? foiAtualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormImovelPage(imovelParaEditar: imovel),
      ),
    );
    if (foiAtualizado == true) {
      _carregarDados(); // Recarrega os dados do imóvel se ele foi editado
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Imovel?>(
      future: _imovelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Imóvel não encontrado.')));
        }

        final imovel = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('${imovel.logradouro}, ${imovel.numero ?? 'S/N'}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar Cadastro do Imóvel',
                onPressed: () => _navegarParaEditarImovel(imovel),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoCard(imovel),
              const SizedBox(height: 24),
              Text(
                'Histórico de Visitas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const Divider(),
              _buildHistoryList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(Imovel imovel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados Cadastrais', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, 'Endereço', '${imovel.logradouro}, ${imovel.numero ?? 'S/N'} - ${imovel.complemento ?? ''}'),
            _buildInfoRow(Icons.map_outlined, 'CEP', imovel.cep ?? 'Não informado'),
            _buildInfoRow(Icons.home_work_outlined, 'Tipo de Imóvel', imovel.tipoImovel ?? 'Não informado'),
            _buildInfoRow(Icons.groups_outlined, 'Nº de Moradores', imovel.quantidadeMoradores?.toString() ?? 'Não informado'),
            _buildInfoRow(Icons.gps_fixed, 'Coordenadas', 'Lat: ${imovel.latitude.toStringAsFixed(5)}, Lon: ${imovel.longitude.toStringAsFixed(5)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ]))),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return FutureBuilder<List<dynamic>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Nenhuma visita registrada para este imóvel.'));
        }

        final visitas = snapshot.data![0] as List<Visita>;
        final campanhas = snapshot.data![1] as List<Campanha>;
        final acoes = snapshot.data![2] as List<Acao>;

        if (visitas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: Text('Nenhuma visita registrada.')),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visitas.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final visita = visitas[index];
            final campanha = campanhas.firstWhereOrNull((c) => c.id == visita.campanhaId);
            final acao = acoes.firstWhereOrNull((a) => a.id == visita.acaoId);

            return ListTile(
              title: Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(visita.dataVisita)}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campanha: ${campanha?.nome ?? 'Desconhecida'}'),
                  Text('Agente: ${visita.nomeAgente}'),
                  _buildVisitaDetails(visita, campanha),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildVisitaDetails(Visita visita, Campanha? campanha) {
    if (campanha == null || visita.dadosFormulario == null) return const SizedBox.shrink();

    try {
      final data = jsonDecode(visita.dadosFormulario!);
      
      switch (campanha.tipoCampanha) {
        case 'dengue':
          final status = StatusFoco.values.firstWhere((e) => e.name == data['statusFoco'], orElse: () => StatusFoco.semFoco);
          return Text('Resultado: ${status.name}', style: const TextStyle(fontWeight: FontWeight.bold));
        case 'covid':
          return Text('Vacinados: ${data['moradoresVacinados']}, Casos: ${data['casosConfirmados']}', style: const TextStyle(fontWeight: FontWeight.bold));
        default:
          return const SizedBox.shrink();
      }
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}