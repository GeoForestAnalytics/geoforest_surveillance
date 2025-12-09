// lib/pages/projetos/detalhes_campanha_page.dart (VERSÃO ATUALIZADA)

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/pages/acoes/form_acao_page.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/pages/importacao/importar_postos_page.dart';
import 'package:geo_forest_surveillance/pages/acoes/importar_setores_page.dart';


class DetalhesCampanhaPage extends StatefulWidget {
  final int campanhaId;

  const DetalhesCampanhaPage({
    super.key, 
    required this.campanhaId
  });

  @override
  State<DetalhesCampanhaPage> createState() => _DetalhesCampanhaPageState();
}

class _DetalhesCampanhaPageState extends State<DetalhesCampanhaPage> {
  final _campanhaRepository = CampanhaRepository();
  final _acaoRepository = AcaoRepository();

  late Future<Campanha?> _campanhaFuture;
  late Future<List<Acao>> _acoesFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _campanhaFuture = _campanhaRepository.getCampanhaById(widget.campanhaId);
      _acoesFuture = _acaoRepository.getAcoesDaCampanha(widget.campanhaId);
    });
  }

  void _navegarParaNovaAcao() async {
    final bool? acaoCriada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormAcaoPage(campanhaId: widget.campanhaId),
      ),
    );
    if (acaoCriada == true) {
      _carregarDados();
    }
  }

  Future<void> _criarAcaoPadraoEImportarSetores() async {
    final novaAcao = Acao(
      campanhaId: widget.campanhaId,
      tipo: 'Ciclo de Importação',
      descricao: 'Ação gerada para importação de setores via GeoJSON.',
      dataCriacao: DateTime.now(),
    );
    final acaoId = await _acaoRepository.insertAcao(novaAcao);

    if (!mounted) return;

    final bool? importou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ImportarSetoresPage(acaoId: acaoId),
      ),
    );

    if (importou == true) {
      _carregarDados();
    }
  }

  // >> NOVA FUNÇÃO PARA NAVEGAR PARA A IMPORTAÇÃO DE POSTOS <<
  Future<void> _navegarParaImportarPostos() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ImportarPostosPage(),
      ),
    );
    // Não é necessário recarregar os dados desta tela, pois os postos são globais
  }

  void _navegarParaDetalhesAcao(Acao acao) {
    context.push('/campanhas/${widget.campanhaId}/acoes/${acao.id}');
  }

  Future<void> _deletarAcao(Acao acao) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja apagar a ação "${acao.tipo}" e todos os seus dados associados?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _acaoRepository.deleteAcao(acao.id!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ação apagada.'), backgroundColor: Colors.green));
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGerente = context.watch<LicenseProvider>().licenseData?.cargo == 'gerente';

    return FutureBuilder<Campanha?>(
      future: _campanhaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: const Center(child: Text('Campanha não encontrada.')));
        }

        final campanha = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(campanha.nome),
            // O botão foi removido daqui para ficar no corpo da tela
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: const EdgeInsets.all(12.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Detalhes da Campanha', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(height: 20),
                      Text("Órgão Responsável: ${campanha.orgaoResponsavel}", style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Data de Criação: ${DateFormat('dd/MM/yyyy').format(campanha.dataCriacao)}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: Text(
                  "Ações / Ciclos da Campanha",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Acao>>(
                  future: _acoesFuture,
                  builder: (context, acoesSnapshot) {
                    if (acoesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (acoesSnapshot.hasError) {
                      return Center(child: Text('Erro ao carregar ações: ${acoesSnapshot.error}'));
                    }

                    final acoes = acoesSnapshot.data ?? [];

                    if (acoes.isEmpty) {
                      // >> WIDGET DE ESTADO VAZIO ATUALIZADO COM OS DOIS BOTÕES <<
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch, // Para os botões ocuparem a largura
                            children: [
                              const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma ação encontrada.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Comece importando os setores ou crie uma ação manualmente.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _criarAcaoPadraoEImportarSetores,
                                icon: const Icon(Icons.upload_file_outlined),
                                label: const Text('Importar Setores (GeoJSON)'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 12), // Espaço entre os botões
                              ElevatedButton.icon(
                                onPressed: _navegarParaImportarPostos,
                                icon: const Icon(Icons.add_location_alt_outlined),
                                label: const Text('Importar Postos'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: acoes.length,
                      itemBuilder: (context, index) {
                        final acao = acoes[index];
                        return Slidable(
                           key: ValueKey(acao.id),
                           endActionPane: ActionPane(
                             motion: const StretchMotion(),
                             children: [
                               SlidableAction(
                                 onPressed: (_) => _deletarAcao(acao),
                                 backgroundColor: Colors.red,
                                 foregroundColor: Colors.white,
                                 icon: Icons.delete_outline,
                                 label: 'Excluir',
                               ),
                             ],
                           ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.directions_walk_outlined, size: 30),
                              title: Text(acao.tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(acao.descricao ?? 'Sem descrição'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () => _navegarParaDetalhesAcao(acao),
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
          floatingActionButton: isGerente
              ? FloatingActionButton.extended(
                  onPressed: _navegarParaNovaAcao,
                  tooltip: 'Criar Nova Ação Manualmente',
                  icon: const Icon(Icons.add_task),
                  label: const Text('Nova Ação'),
                )
              : null,
        );
      },
    );
  }
}