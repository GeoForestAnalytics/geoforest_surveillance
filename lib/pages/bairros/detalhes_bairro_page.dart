// lib/pages/bairros/detalhes_bairro_page.dart

import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Import necessário para 'firstWhereOrNull'

// Imports da nova arquitetura
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/imovel_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/pages/cadastro/form_imovel_page.dart';
import 'package:geo_forest_surveillance/pages/visitas/form_visita_page.dart';
// =======================================================
// >> IMPORT DA NOVA PÁGINA DE DETALHES <<
// =======================================================
import 'package:geo_forest_surveillance/pages/cadastro/detalhes_imovel_page.dart';


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
  // Repositórios necessários para esta tela
  final _bairroRepository = BairroRepository();
  final _imovelRepository = ImovelRepository();
  final _visitaRepository = VisitaRepository();
  final _campanhaRepository = CampanhaRepository();
  final _acaoRepository = AcaoRepository();

  // Futures para carregar todos os dados necessários
  late Future<Bairro?> _bairroFuture;
  late Future<Campanha?> _campanhaFuture;
  late Future<Acao?> _acaoFuture;
  late Future<List<Imovel>> _imoveisFuture;
  // Mapa para armazenar a contagem de visitas por imóvel
  Map<int, int> _visitasCount = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _bairroFuture = _getBairroDetails();
      _campanhaFuture = _campanhaRepository.getCampanhaById(widget.campanhaId);
      _acaoFuture = _acaoRepository.getAcaoById(widget.acaoId);
      _imoveisFuture = _imovelRepository.getImoveisDoBairro(widget.bairroId);
    });

    final imoveis = await _imoveisFuture;
    final newCounts = <int, int>{};
    for (final imovel in imoveis) {
      if (imovel.id != null) {
        final visitas = await _visitaRepository.getVisitasDoImovel(imovel.id!);
        newCounts[imovel.id!] = visitas.length;
      }
    }
    if (mounted) {
      setState(() {
        _visitasCount = newCounts;
      });
    }
  }

  Future<Bairro?> _getBairroDetails() async {
    final bairros = await _bairroRepository.getBairrosDoMunicipio(widget.municipioId, widget.acaoId);
    return bairros.firstWhereOrNull((b) => b.id == widget.bairroId);
  }

  void _navegarParaNovoImovel(int bairroId) async {
    final bool? foiCriado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormImovelPage(bairroId: bairroId),
      ),
    );
    if (foiCriado == true) {
      _carregarDados();
    }
  }

  void _navegarParaNovaVisita(Imovel imovel, Campanha campanha, Acao acao) async {
    final bool? foiCriado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormVisitaPage(
          imovel: imovel,
          campanha: campanha,
          acao: acao,
        ),
      ),
    );
    if (foiCriado == true) {
      _carregarDados();
    }
  }

  // =======================================================
  // >> NOVA FUNÇÃO DE NAVEGAÇÃO PARA DETALHES <<
  // =======================================================
  void _navegarParaDetalhesImovel(Imovel imovel) async {
    // Navega para a nova tela de detalhes e, se algo for atualizado lá,
    // recarrega os dados desta tela.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesImovelPage(imovelId: imovel.id!),
      ),
    );
    if (result == true) {
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_bairroFuture, _campanhaFuture, _acaoFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }

        final bairro = snapshot.data?[0] as Bairro?;
        final campanha = snapshot.data?[1] as Campanha?;
        final acao = snapshot.data?[2] as Acao?;

        if (bairro == null || campanha == null || acao == null) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Não foi possível carregar os dados do setor.')));
        }

        return Scaffold(
          appBar: AppBar(title: Text(bairro.nome)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  "Imóveis Cadastrados",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Imovel>>(
                  future: _imoveisFuture,
                  builder: (context, imoveisSnapshot) {
                    if (imoveisSnapshot.connectionState == ConnectionState.waiting && _visitasCount.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final imoveis = imoveisSnapshot.data ?? [];
                    if (imoveis.isEmpty) {
                      return const Center(
                        child: Text('Nenhum imóvel cadastrado neste setor.\nClique no botão "+" para iniciar.', textAlign: TextAlign.center),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: imoveis.length,
                      itemBuilder: (context, index) {
                        final imovel = imoveis[index];
                        final visitasRealizadas = _visitasCount[imovel.id] ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.home_work_outlined)),
                              title: Text('${imovel.logradouro}, ${imovel.numero ?? 'S/N'}'),
                              subtitle: Text('Visitas realizadas: $visitasRealizadas'),
                              trailing: ElevatedButton(
                                onPressed: () => _navegarParaNovaVisita(imovel, campanha, acao),
                                child: const Text('Visitar'),
                              ),
                              // =======================================================
                              // >> AÇÃO DE TOQUE ADICIONADA AQUI <<
                              // =======================================================
                              onTap: () => _navegarParaDetalhesImovel(imovel),
                            ),
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
            onPressed: () => _navegarParaNovoImovel(bairro.id!),
            tooltip: 'Cadastrar Novo Imóvel no Setor',
            icon: const Icon(Icons.add_home_outlined),
            label: const Text('Novo Imóvel'),
          ),
        );
      },
    );
  }
}