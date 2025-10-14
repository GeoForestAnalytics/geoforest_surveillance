// lib/pages/acoes/detalhes_acao_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/municipio_model.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/municipio_repository.dart';
import 'package:geo_forest_surveillance/pages/municipios/form_municipio_page.dart';

class DetalhesAcaoPage extends StatefulWidget {
  final int campanhaId;
  final int acaoId;

  const DetalhesAcaoPage({
    super.key,
    required this.campanhaId,
    required this.acaoId,
  });

  @override
  State<DetalhesAcaoPage> createState() => _DetalhesAcaoPageState();
}

class _DetalhesAcaoPageState extends State<DetalhesAcaoPage> {
  final _acaoRepository = AcaoRepository();
  final _municipioRepository = MunicipioRepository();

  late Future<Acao?> _acaoFuture;
  late Future<List<Municipio>> _municipiosFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _acaoFuture = _acaoRepository.getAcaoById(widget.acaoId);
      _municipiosFuture = _municipioRepository.getMunicipiosDaAcao(widget.acaoId);
    });
  }

  void _navegarParaNovoMunicipio() async {
    final bool? foiCriado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FormMunicipioPage(acaoId: widget.acaoId)),
    );
    if (foiCriado == true) {
      _carregarDados();
    }
  }
  
  void _navegarParaDetalhesMunicipio(Municipio municipio) {
    context.push('/campanhas/${widget.campanhaId}/acoes/${widget.acaoId}/municipios/${municipio.id}');
  }

  Future<void> _deletarMunicipio(Municipio municipio) async {
    final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Confirmar Remoção'),
            content: Text('Deseja remover o município "${municipio.nome}" desta ação?'),
            actions: [
                TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop(false)),
                FilledButton(child: const Text('Remover'), onPressed: () => Navigator.of(ctx).pop(true), style: FilledButton.styleFrom(backgroundColor: Colors.red)),
            ],
        ),
    );
    if (confirmar == true) {
        await _municipioRepository.deleteMunicipio(municipio.id, municipio.acaoId);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Município removido.')));
        _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Acao?>(
      future: _acaoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Ação não encontrada.')));
        }

        final acao = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: Text(acao.tipo)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Detalhes da Ação', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(height: 20),
                      Text("Descrição: ${acao.descricao ?? 'N/A'}", style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Data de Criação: ${DateFormat('dd/MM/yyyy').format(acao.dataCriacao)}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Text("Municípios / Setores de Atuação", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
              Expanded(
                child: FutureBuilder<List<Municipio>>(
                  future: _municipiosFuture,
                  builder: (context, municipiosSnapshot) {
                    if (municipiosSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final municipios = municipiosSnapshot.data ?? [];
                    if (municipios.isEmpty) {
                      return const Center(child: Text('Nenhum município adicionado a esta ação.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: municipios.length,
                      itemBuilder: (context, index) {
                        final municipio = municipios[index];
                        return Slidable(
                           key: ValueKey('${municipio.id}-${municipio.acaoId}'),
                           endActionPane: ActionPane(
                             motion: const StretchMotion(),
                             children: [SlidableAction(onPressed: (_) => _deletarMunicipio(municipio), backgroundColor: Colors.red, icon: Icons.delete_outline, label: 'Remover')],
                           ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.location_city_outlined),
                              title: Text(municipio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('UF: ${municipio.uf.toUpperCase()}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () => _navegarParaDetalhesMunicipio(municipio),
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
            onPressed: _navegarParaNovoMunicipio,
            tooltip: 'Adicionar Município',
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Novo Município'),
          ),
        );
      },
    );
  }
}