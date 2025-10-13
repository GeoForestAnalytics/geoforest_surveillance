// lib/pages/projetos/detalhes_campanha_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Imports atualizados para a lógica de Dengue
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
// import 'package:geo_forest_surveillance/pages/acoes/form_acao_page.dart'; // Você criará este arquivo a seguir
// import 'package:geo_forest_surveillance/pages/acoes/detalhes_acao_page.dart'; // Você criará este arquivo a seguir

class DetalhesCampanhaPage extends StatefulWidget {
  final Campanha campanha;
  const DetalhesCampanhaPage({super.key, required this.campanha});

  @override
  State<DetalhesCampanhaPage> createState() => _DetalhesCampanhaPageState();
}

class _DetalhesCampanhaPageState extends State<DetalhesCampanhaPage> {
  late Future<List<Acao>> _acoesFuture;
  final _acaoRepository = AcaoRepository();

  @override
  void initState() {
    super.initState();
    _carregarAcoes();
  }

  void _carregarAcoes() {
    if (mounted) {
      setState(() {
        _acoesFuture = _acaoRepository.getAcoesDaCampanha(widget.campanha.id!);
      });
    }
  }

  void _navegarParaNovaAcao() async {
    /*
    // Esta navegação será implementada quando você criar a página 'form_acao_page.dart'
    final bool? acaoCriada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormAcaoPage(campanhaId: widget.campanha.id!),
      ),
    );
    if (acaoCriada == true && mounted) {
      _carregarAcoes();
    }
    */
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegação para nova ação a ser implementada.')));
  }

  void _navegarParaDetalhesAcao(Acao acao) {
     /*
    // Esta navegação será implementada quando você criar a página 'detalhes_acao_page.dart'
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DetalhesAcaoPage(acao: acao)),
    ).then((_) => _carregarAcoes());
    */
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegação para detalhes da ação a ser implementada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campanha.nome),
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
                  Text("Órgão Responsável: ${widget.campanha.orgaoResponsavel}", style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Data de Criação: ${DateFormat('dd/MM/yyyy').format(widget.campanha.dataCriacao)}', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text(
              "Ações da Campanha",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Acao>>(
              future: _acoesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar ações: ${snapshot.error}'));
                }

                final acoes = snapshot.data ?? [];

                if (acoes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhuma ação encontrada.\nClique no botão "+" para adicionar a primeira.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: acoes.length,
                  itemBuilder: (context, index) {
                    final acao = acoes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.directions_walk_outlined),
                        title: Text(acao.tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(acao.descricao ?? 'Sem descrição'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => _navegarParaDetalhesAcao(acao),
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
              onPressed: _navegarParaNovaAcao,
              tooltip: 'Nova Ação',
              icon: const Icon(Icons.add_task),
              label: const Text('Nova Ação'),
            ),
    );
  }
}