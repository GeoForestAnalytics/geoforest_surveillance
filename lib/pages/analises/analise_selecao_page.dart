// lib/pages/analises/analise_selecao_page.dart
import 'package:flutter/material.dart';

// Imports dos modelos e repositórios de Dengue
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
// import 'package:geo_forest_surveillance/pages/analises/relatorio_campanha_page.dart'; // Você criará esta página

class AnaliseSelecaoPage extends StatefulWidget {
  const AnaliseSelecaoPage({super.key});

  @override
  State<AnaliseSelecaoPage> createState() => _AnaliseSelecaoPageState();
}

class _AnaliseSelecaoPageState extends State<AnaliseSelecaoPage> {
  final _campanhaRepository = CampanhaRepository();
  final _acaoRepository = AcaoRepository();

  List<Campanha> _campanhasDisponiveis = [];
  Campanha? _campanhaSelecionada;
  
  List<Acao> _acoesDaCampanha = [];
  final Set<int> _acoesSelecionadas = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarCampanhas();
  }

  Future<void> _carregarCampanhas() async {
    // TODO: A lógica para carregar campanhas (similar à de 'selecao_acao_mapa_page')
    // viria aqui, provavelmente buscando todas as campanhas que o gerente pode ver.
  }

  Future<void> _onCampanhaChanged(Campanha? novaCampanha) async {
    if (novaCampanha == null) return;
    
    setState(() {
      _isLoading = true;
      _campanhaSelecionada = novaCampanha;
      _acoesDaCampanha.clear();
      _acoesSelecionadas.clear();
    });
    
    final acoes = await _acaoRepository.getAcoesDaCampanha(novaCampanha.id!);

    if(mounted) {
      setState(() {
        _acoesDaCampanha = acoes;
        _isLoading = false;
      });
    }
  }

  void _gerarRelatorio() {
    if (_campanhaSelecionada == null || _acoesSelecionadas.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecione uma campanha e pelo menos uma ação.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    // TODO: Navegar para uma página de relatório, passando os IDs selecionados
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => RelatorioCampanhaPage(
    //     campanha: _campanhaSelecionada!,
    //     acaoIds: _acoesSelecionadas,
    //   ),
    // ));
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Navegação para o relatório a ser implementada.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análise de Vigilância')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown para selecionar a Campanha
            DropdownButtonFormField<Campanha>(
              value: _campanhaSelecionada,
              hint: const Text('1. Selecione uma Campanha'),
              isExpanded: true,
              items: _campanhasDisponiveis.map((campanha) {
                return DropdownMenuItem(value: campanha, child: Text(campanha.nome));
              }).toList(),
              onChanged: _onCampanhaChanged,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('2. Selecione as Ações para incluir na análise', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _campanhaSelecionada == null
                  ? const Center(child: Text('Aguardando seleção de campanha.'))
                  : ListView(
                      children: _acoesDaCampanha.map((acao) {
                        return CheckboxListTile(
                          title: Text(acao.tipo),
                          subtitle: Text(acao.descricao ?? ''),
                          value: _acoesSelecionadas.contains(acao.id!),
                          onChanged: (isSelected) {
                            setState(() {
                              if (isSelected == true) {
                                _acoesSelecionadas.add(acao.id!);
                              } else {
                                _acoesSelecionadas.remove(acao.id!);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _gerarRelatorio,
        label: const Text('Gerar Relatório'),
        icon: const Icon(Icons.analytics_outlined),
      ),
    );
  }
}