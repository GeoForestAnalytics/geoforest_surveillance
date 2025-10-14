// lib/pages/bairros/detalhes_bairro_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/pages/focos/form_foco_page.dart'; // Será criado a seguir

class DetalhesBairroPage extends StatefulWidget {
  final int campanhaId;
  final int acaoId;
  final String municipioId;
  final int bairroId;

  const DetalhesBairroPage({
    super.key,
    required this.campanhaId,
    required this.acaoId,
    required this.municipioId,
    required this.bairroId,
  });

  @override
  State<DetalhesBairroPage> createState() => _DetalhesBairroPageState();
}

class _DetalhesBairroPageState extends State<DetalhesBairroPage> {
  final _bairroRepository = BairroRepository();
  final _focoRepository = FocoRepository();

  late Future<Bairro?> _bairroFuture;
  late Future<List<FocoDengue>> _focosFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      // TODO: Criar getBairroById no repository
      // _bairroFuture = _bairroRepository.getBairroById(widget.bairroId);
      _focosFuture = _focoRepository.getFocosDoBairro(widget.bairroId);
    });
  }
  
  void _navegarParaNovoFoco(Bairro bairro) async {
    final bool? foiCriado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FormFocoPage(bairro: bairro, campanhaId: widget.campanhaId)),
    );
    if (foiCriado == true) {
      _carregarDados();
    }
  }

  void _navegarParaDetalhesFoco(FocoDengue foco) {
    // TODO: Implementar navegação para edição de foco se necessário
  }

  IconData _getIconForStatus(StatusFoco status) {
    switch (status) {
      case StatusFoco.focoEliminado:
      case StatusFoco.tratado:
        return Icons.bug_report;
      case StatusFoco.potencial:
        return Icons.opacity;
      case StatusFoco.semFoco:
        return Icons.check_circle;
      case StatusFoco.fechado:
        return Icons.lock;
      case StatusFoco.recusado:
        return Icons.do_not_disturb_on;
    }
  }
  
  Color _getColorForStatus(StatusFoco status) {
    switch (status) {
      case StatusFoco.focoEliminado:
      case StatusFoco.tratado:
        return Colors.red;
      case StatusFoco.potencial:
        return Colors.orange;
      case StatusFoco.semFoco:
        return Colors.green;
      case StatusFoco.fechado:
      case StatusFoco.recusado:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bairro>>( // Usando a lista para encontrar o bairro
      future: _bairroRepository.getBairrosDoMunicipio(widget.municipioId, widget.acaoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final bairro = snapshot.data?.firstWhere((b) => b.id == widget.bairroId);
        if (bairro == null) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Bairro não encontrado.')));
        }

        return Scaffold(
          appBar: AppBar(title: Text(bairro.nome)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text("Vistorias Realizadas", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
              Expanded(
                child: FutureBuilder<List<FocoDengue>>(
                  future: _focosFuture,
                  builder: (context, focosSnapshot) {
                    if (focosSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final focos = focosSnapshot.data ?? [];
                    if (focos.isEmpty) {
                      return const Center(child: Text('Nenhuma vistoria registrada.\nClique no botão "+" para iniciar.', textAlign: TextAlign.center,));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: focos.length,
                      itemBuilder: (context, index) {
                        final foco = focos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForStatus(foco.statusFoco),
                              child: Icon(_getIconForStatus(foco.statusFoco), color: Colors.white),
                            ),
                            title: Text(foco.endereco, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Agente: ${foco.nomeAgente}\nData: ${DateFormat('dd/MM/yyyy').format(foco.dataVisita)}'),
                            onTap: () => _navegarParaDetalhesFoco(foco),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navegarParaNovoFoco(bairro),
            tooltip: 'Registrar Nova Vistoria',
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Nova Vistoria'),
          ),
        );
      },
    );
  }
}