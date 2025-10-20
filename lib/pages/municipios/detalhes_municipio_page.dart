// lib/pages/municipios/detalhes_municipio_page.dart (VERSÃO FINAL E CORRIGIDA)

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/municipio_model.dart';
import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/data/repositories/municipio_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';
import 'package:geo_forest_surveillance/pages/bairros/form_bairro_page.dart';
// =======================================================
// >> IMPORT ADICIONADO AQUI <<
// =======================================================
import 'package:geo_forest_surveillance/models/setor_com_posto_viewmodel.dart';


class DetalhesMunicipioPage extends StatefulWidget {
  final int campanhaId;
  final int acaoId;
  final String municipioId;

  const DetalhesMunicipioPage({
    super.key,
    required this.campanhaId,
    required this.acaoId,
    required this.municipioId,
  });

  @override
  State<DetalhesMunicipioPage> createState() => _DetalhesMunicipioPageState();
}

class _DetalhesMunicipioPageState extends State<DetalhesMunicipioPage> {
  final _municipioRepository = MunicipioRepository();
  final _bairroRepository = BairroRepository();

  // O Future para buscar o município continua o mesmo
  late Future<List<Municipio>> _municipioFuture; 
  // =======================================================
  // >> TIPO DO FUTURE DE BAIRROS ATUALIZADO <<
  // =======================================================
  late Future<List<SetorComPosto>> _setoresFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      // A busca pelo município continua igual
      _municipioFuture = _municipioRepository.getMunicipiosDaAcao(widget.acaoId);
      // =======================================================
      // >> CHAMADA AO NOVO MÉTODO DO REPOSITORY <<
      // =======================================================
      _setoresFuture = _bairroRepository.getSetoresComPosto(widget.municipioId, widget.acaoId);
    });
  }
  
  void _navegarParaNovoBairro() async {
    final bool? foiCriado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FormBairroPage(acaoId: widget.acaoId, municipioId: widget.municipioId)),
    );
    if (foiCriado == true && mounted) {
      _carregarDados();
    }
  }
  
  void _navegarParaDetalhesBairro(Bairro bairro) {
    context.push('/campanhas/${widget.campanhaId}/acoes/${widget.acaoId}/municipios/${widget.municipioId}/bairros/${bairro.id}');
  }

  Future<void> _deletarBairro(Bairro bairro) async {
    // Implementar diálogo de confirmação
    if (bairro.id != null) {
      await _bairroRepository.deleteBairro(bairro.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bairro/Setor removido.')));
        _carregarDados();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Municipio>>(
      future: _municipioFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Município não encontrado.')));
        }

        final municipio = snapshot.data!.firstWhere((m) => m.id == widget.municipioId, orElse: () => Municipio(id: '', acaoId: 0, nome: 'Não encontrado', uf: ''));

        return Scaffold(
          appBar: AppBar(title: Text(municipio.nome)),
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
                      Text('Setor de Atuação', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(height: 20),
                      Text("Município: ${municipio.nome} - ${municipio.uf}", style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      // Mantido o ID do Setor, que neste contexto é o ID do Município na Ação
                      Text("ID do Setor: ${municipio.id}", style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Text("Bairros / Quadras", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
              Expanded(
                // =======================================================
                // >> FUTUREBUILDER ATUALIZADO PARA 'SetorComPosto' <<
                // =======================================================
                child: FutureBuilder<List<SetorComPosto>>(
                  future: _setoresFuture,
                  builder: (context, setoresSnapshot) {
                    if (setoresSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final setores = setoresSnapshot.data ?? [];
                    if (setores.isEmpty) {
                      return const Center(child: Text('Nenhum bairro/setor cadastrado.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: setores.length,
                      itemBuilder: (context, index) {
                        final setorInfo = setores[index];
                        final bairro = setorInfo.bairro;

                        return Slidable(
                           key: ValueKey(bairro.id),
                           endActionPane: ActionPane(
                             motion: const StretchMotion(),
                             children: [SlidableAction(onPressed: (_) => _deletarBairro(bairro), backgroundColor: Colors.red, icon: Icons.delete_outline, label: 'Excluir')],
                           ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.holiday_village_outlined),
                              title: Text(bairro.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              // =======================================================
                              // >> SUBTÍTULO CORRIGIDO PARA MOSTRAR O NOME DO POSTO <<
                              // =======================================================
                              subtitle: Text('Posto: ${setorInfo.nomePosto}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () => _navegarParaDetalhesBairro(bairro),
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
            onPressed: _navegarParaNovoBairro,
            tooltip: 'Adicionar Bairro/Setor',
            icon: const Icon(Icons.add),
            label: const Text('Novo Bairro'),
          ),
        );
      },
    );
  }
}