// lib/pages/planejamento/selecao_acao_mapa_page.dart

import 'package:flutter/material.dart';
import 'package:geo_forest_surveillance/providers/map_provider.dart';
import 'package:provider/provider.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
// import 'package:geo_forest_surveillance/providers/map_provider.dart';
import 'package:geo_forest_surveillance/pages/planejamento/mapa_planejamento_page.dart'; // Será criada a seguir


class SelecaoAcaoMapaPage extends StatefulWidget {
  const SelecaoAcaoMapaPage({super.key});

  @override
  State<SelecaoAcaoMapaPage> createState() => _SelecaoAcaoMapaPageState();
}

class _SelecaoAcaoMapaPageState extends State<SelecaoAcaoMapaPage> {
  final _campanhaRepository = CampanhaRepository();
  final _acaoRepository = AcaoRepository();

  Future<List<Campanha>>? _campanhasFuture;
  final Map<int, List<Acao>> _acoesPorCampanha = {};
  bool _isLoadingAcoes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCampanhas();
    });
  }

  Future<void> _carregarCampanhas() async {
    final licenseProvider = context.read<LicenseProvider>();
    final licenseId = licenseProvider.licenseData?.id;
    final isGerente = licenseProvider.licenseData?.cargo == 'gerente';

    if (licenseId == null) {
      setState(() => _campanhasFuture = Future.value([]));
      return;
    }
    
    setState(() {
      // Se for gerente, busca todas. Se for equipe, busca apenas as da sua licença.
      _campanhasFuture = isGerente 
          ? _campanhaRepository.getTodasAsCampanhasParaGerente()
          : _campanhaRepository.getTodasCampanhas(licenseId);
    });
  }

  Future<void> _carregarAcoesDaCampanha(int campanhaId) async {
    if (_acoesPorCampanha.containsKey(campanhaId)) return;

    setState(() => _isLoadingAcoes = true);
    final acoes = await _acaoRepository.getAcoesDaCampanha(campanhaId);
    if (mounted) {
      setState(() {
        _acoesPorCampanha[campanhaId] = acoes;
        _isLoadingAcoes = false;
      });
    }
  }

  void _navegarParaMapa(Acao acao) {
    // <<< SUBSTITUA A LÓGICA ANTIGA POR ESTA >>>
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    // Limpa dados de mapas anteriores e define a ação atual
    mapProvider.clearAllMapData();
    mapProvider.setCurrentAcao(acao);
    
    // Carrega os pontos (focos) salvos localmente para esta ação
    mapProvider.loadPontosParaAcao(); 

    // Navega para a nova página do mapa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapaPlanejamentoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Ação para o Mapa'),
      ),
      body: FutureBuilder<List<Campanha>>(
        future: _campanhasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final campanhas = snapshot.data ?? [];
          if (campanhas.isEmpty) {
            return const Center(child: Text('Nenhuma campanha encontrada.'));
          }

          return ListView.builder(
            itemCount: campanhas.length,
            itemBuilder: (context, index) {
              final campanha = campanhas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text(campanha.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.campaign),
                  onExpansionChanged: (isExpanding) {
                    if (isExpanding) {
                      _carregarAcoesDaCampanha(campanha.id!);
                    }
                  },
                  children: [
                    if (_isLoadingAcoes && !_acoesPorCampanha.containsKey(campanha.id))
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_acoesPorCampanha[campanha.id]?.isEmpty ?? true)
                      const ListTile(title: Text('Nenhuma ação nesta campanha.'))
                    else
                      ..._acoesPorCampanha[campanha.id]!.map((acao) {
                        return ListTile(
                          title: Text(acao.tipo),
                          subtitle: Text(acao.descricao ?? 'Sem descrição'),
                          leading: const Icon(Icons.arrow_right),
                          onTap: () => _navegarParaMapa(acao),
                          trailing: const Icon(Icons.map_outlined, color: Colors.grey),
                        );
                      }).toList()
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}