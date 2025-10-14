// lib/pages/projetos/lista_campanhas_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/pages/projetos/form_campanha_page.dart';

// <<< ESTA É A DECLARAÇÃO CORRETA DA CLASSE >>>
class ListaCampanhasPage extends StatefulWidget {
  final String title;
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
  final _campanhaRepository = CampanhaRepository();
  List<Campanha> _campanhas = [];
  bool _isLoading = true;
  bool _isGerente = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosIniciais();
    });
  }

  Future<void> _carregarDadosIniciais() async {
    final licenseProvider = context.read<LicenseProvider>();
    if (mounted) {
      setState(() {
        _isGerente = licenseProvider.licenseData?.cargo == 'gerente';
      });
    }
    await _carregarCampanhas();
  }

  Future<void> _carregarCampanhas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final licenseId = context.read<LicenseProvider>().licenseData?.id;
    if (licenseId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final data = await _campanhaRepository.getTodasAsCampanhasParaGerente();
    
    if (mounted) {
      setState(() {
        _campanhas = data.where((c) => c.status != 'deletado').toList();
        _isLoading = false;
      });
    }
  }

  void _navegarParaNovaCampanha() async {
    final bool? foiCriado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const FormCampanhaPage()),
    );
    if (foiCriado == true) {
      _carregarCampanhas();
    }
  }
  
  void _navegarParaEdicao(Campanha campanha) async {
    final bool? foiEditado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FormCampanhaPage(campanhaParaEditar: campanha)),
    );
    if (foiEditado == true) {
      _carregarCampanhas();
    }
  }
  
  void _navegarParaDetalhes(Campanha campanha) {
    context.push('/campanhas/${campanha.id}');
  }
  
  Future<void> _deletarCampanha(Campanha campanha) async {
     final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja apagar a campanha "${campanha.nome}" e todos os seus dados?'),
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
      await _campanhaRepository.deleteCampanha(campanha.id!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campanha apagada.')));
      _carregarCampanhas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campanhas.isEmpty
              ? _buildEmptyState()
              : _buildListView(),
      floatingActionButton: _isGerente ? FloatingActionButton.extended(
        onPressed: _navegarParaNovaCampanha,
        icon: const Icon(Icons.add),
        label: const Text('Nova Campanha'),
      ) : null,
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _campanhas.length,
      itemBuilder: (context, index) {
        final campanha = _campanhas[index];
        return Slidable(
          key: ValueKey(campanha.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(onPressed: (_) => _navegarParaEdicao(campanha), backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, icon: Icons.edit_outlined, label: 'Editar'),
            ],
          ),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            children: [
              SlidableAction(onPressed: (_) => _deletarCampanha(campanha), backgroundColor: Colors.red, foregroundColor: Colors.white, icon: Icons.delete_outline, label: 'Excluir'),
            ],
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.campaign_outlined, color: Theme.of(context).colorScheme.primary, size: 40),
              title: Text(campanha.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Órgão: ${campanha.orgaoResponsavel}'),
              trailing: Text(DateFormat('dd/MM/yy').format(campanha.dataCriacao)),
              onTap: () => _navegarParaDetalhes(campanha),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Nenhuma campanha encontrada.', style: TextStyle(fontSize: 18)),
            if (_isGerente)
              const Text('Use o botão "+" para criar a primeira campanha.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}