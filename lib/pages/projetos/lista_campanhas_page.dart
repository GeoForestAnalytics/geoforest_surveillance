// lib/pages/projetos/lista_campanhas_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// <<< 1. IMPORTS ATUALIZADOS >>>
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';


class ListaCampanhasPage extends StatefulWidget {
  final String title;
  // A lógica de importação pode ser mantida e adaptada depois
  final bool isImporting; 

  const ListaCampanhasPage({
    super.key,
    required this.title,
    this.isImporting = false,
  });

  @override
  State<ListaCampanhasPage> createState() => _ListaCampanhasPageState();
}

class _ListaCampanhasPageState extends State<ListaCampanhasPage> {
  // <<< 2. REPOSITÓRIO E LISTA ATUALIZADOS >>>
  final _campanhaRepository = CampanhaRepository();
  List<Campanha> campanhas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarCampanhas();
    });
  }

   Future<void> _carregarCampanhas() async {
    setState(() => _isLoading = true);
    final licenseProvider = context.read<LicenseProvider>();
    final licenseId = licenseProvider.licenseData?.id;

    if (licenseId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // <<< 3. CHAMADA AO MÉTODO CORRETO >>>
    final data = await _campanhaRepository.getTodasCampanhas(licenseId);
    if (mounted) {
      setState(() {
        campanhas = data;
        _isLoading = false;
      });
    }
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : campanhas.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Criar e navegar para FormCampanhaPage
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Campanha'),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: campanhas.length,
      itemBuilder: (context, index) {
        final campanha = campanhas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.campaign_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            // <<< 4. DADOS DA CAMPANHA EXIBIDOS >>>
            title: Text(campanha.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Responsável: ${campanha.orgaoResponsavel}'),
            trailing: Text(DateFormat('dd/MM/yy').format(campanha.dataCriacao)),
            onTap: () {
              // TODO: Navegar para DetalhesCampanhaPage(campanha: campanha)
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhuma campanha encontrada.', style: TextStyle(fontSize: 18)),
          Text('Use o botão "+" para adicionar uma nova.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}