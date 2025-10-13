// lib/pages/menu/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports atualizados para a nova lógica
import 'package:geo_forest_surveillance/pages/projetos/lista_campanhas_page.dart'; // <-- RENOMEADO
import 'package:geo_forest_surveillance/pages/analises/analise_selecao_page.dart'; // <-- Será a nova página de análise da dengue
import 'package:geo_forest_surveillance/pages/menu/configuracoes_page.dart';
import 'package:geo_forest_surveillance/pages/planejamento/selecao_acao_mapa_page.dart'; // <-- RENOMEADO
import 'package:geo_forest_surveillance/pages/menu/paywall_page.dart';

import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/services/export_service.dart';
import 'package:geo_forest_surveillance/widgets/menu_card.dart';
import 'package:geo_forest_surveillance/services/sync_service.dart';

class HomePage extends StatefulWidget {
  final String title;
  final bool showAppBar;

  const HomePage({
    super.key,
    required this.title,
    this.showAppBar = true,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;

  Future<void> _executarSincronizacao() async {
    // A lógica de sincronização permanece a mesma
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iniciando sincronização...')));
    try {
      final syncService = SyncService(); // O SyncService precisará ser refatorado internamente
      await syncService.sincronizarDados();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados sincronizados!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na sincronização: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ... (outras funções como _mostrarDialogoImportacao, _mostrarAvisoDeUpgrade permanecem)

  @override
  Widget build(BuildContext context) {
    final licenseProvider = context.watch<LicenseProvider>();
    final bool podeAnalisar = licenseProvider.licenseData?.features['analise'] ?? true;

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: Text(widget.title)) : null,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
          children: [
            // <<< ITENS DO MENU ATUALIZADOS >>>
            MenuCard(
              icon: Icons.campaign_outlined,
              label: 'Campanhas e Vistorias',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const ListaCampanhasPage(title: 'Minhas Campanhas'),
              )),
            ),
            MenuCard(
              icon: Icons.map_outlined,
              label: 'Planejamento de Visitas',
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const SelecaoAcaoMapaPage())); // <-- Página renomeada
              },
            ),
            MenuCard(
              icon: Icons.analytics_outlined,
              label: 'Painel de Análise',
              onTap: podeAnalisar
                  ? () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const AnaliseSelecaoPage())); // <-- Esta página será refatorada
                  }
                  : () { /* Lógica de aviso de upgrade */ },
            ),
            MenuCard(
              icon: Icons.file_upload_outlined,
              label: 'Importar Dados',
              onTap: () { /* Lógica de importação */ },
            ),
            MenuCard(
              icon: Icons.file_download_outlined,
              label: 'Exportar Relatórios',
              onTap: () { /* Lógica de exportação */ },
            ),
            MenuCard(
              icon: Icons.settings_outlined,
              label: 'Configurações',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const ConfiguracoesPage()),
              ),
            ),
             MenuCard(
              icon: _isSyncing ? Icons.sync_problem : Icons.sync,
              label: _isSyncing ? 'Sincronizando...' : 'Sincronizar Dados',
              onTap: _isSyncing ? () {} : _executarSincronizacao,
            ),
             MenuCard(
              icon: Icons.credit_card,
              label: 'Assinaturas',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => const PaywallPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
