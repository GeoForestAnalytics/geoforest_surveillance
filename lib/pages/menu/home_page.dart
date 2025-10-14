// lib/pages/menu/home_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Imports
import 'package:geo_forest_surveillance/pages/projetos/lista_campanhas_page.dart';
import 'package:geo_forest_surveillance/pages/analises/analise_selecao_page.dart';
import 'package:geo_forest_surveillance/pages/menu/configuracoes_page.dart';
import 'package:geo_forest_surveillance/pages/planejamento/selecao_acao_mapa_page.dart';
import 'package:geo_forest_surveillance/pages/menu/paywall_page.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/widgets/menu_card.dart';
import 'package:geo_forest_surveillance/services/sync_service.dart';
import 'package:geo_forest_surveillance/models/sync_progress_model.dart';
import 'package:geo_forest_surveillance/providers/gerente_provider.dart';

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
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    
    final syncService = SyncService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StreamBuilder<SyncProgress>(
          stream: syncService.progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data;
            
            if (progress?.concluido == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogContext).pop(); 
                
                if (progress?.erro == null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados sincronizados com sucesso!'), backgroundColor: Colors.green,));
                } else if (progress?.erro != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na sincronização: ${progress!.erro}'), backgroundColor: Colors.red,));
                }

                if (mounted) {
                  context.read<GerenteProvider>().iniciarMonitoramento(); 
                  setState(() => _isSyncing = false);
                }
              });
              return const SizedBox.shrink(); 
            }

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(progress?.mensagem ?? 'Iniciando...'),
                  if ((progress?.totalAProcessar ?? 0) > 0) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: (progress!.processados / progress.totalAProcessar)),
                  ]
                ],
              ),
            );
          },
        );
      },
    );

    try {
      await syncService.sincronizarDados();
    } catch (e) {
      debugPrint("Erro na sincronização capturado na UI: $e");
    }
  }

  void _mostrarAvisoDeUpgrade(BuildContext context, String featureName) {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Funcionalidade indisponível"),
        content: Text("A função '$featureName' não está disponível no seu plano atual."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Entendi")),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/paywall');
            },
            child: const Text("Ver Planos"),
          ),
        ],
      ),
    );
  }

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
            MenuCard(
              icon: Icons.campaign_outlined,
              label: 'Campanhas e Vistorias',
              onTap: () => context.push('/campanhas'),
            ),
            MenuCard(
              icon: Icons.map_outlined,
              label: 'Planejamento de Visitas',
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const SelecaoAcaoMapaPage()));
              },
            ),
            MenuCard(
              icon: Icons.analytics_outlined,
              label: 'Painel de Análise',
              onTap: podeAnalisar
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnaliseSelecaoPage()))
                  : () => _mostrarAvisoDeUpgrade(context, "Painel de Análise"),
            ),
            MenuCard(
              icon: Icons.file_upload_outlined,
              label: 'Importar Dados',
              onTap: () { /* TODO: Lógica de importação */ },
            ),
            MenuCard(
              icon: Icons.file_download_outlined,
              label: 'Exportar Relatórios',
              onTap: () { /* TODO: Lógica de exportação */ },
            ),
            MenuCard(
              icon: Icons.settings_outlined,
              label: 'Configurações',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfiguracoesPage())),
            ),
             MenuCard(
              icon: _isSyncing ? Icons.sync_problem : Icons.sync,
              label: _isSyncing ? 'Sincronizando...' : 'Sincronizar Dados',
              // <<< CORREÇÃO APLICADA AQUI >>>
              onTap: _isSyncing ? null : () => _executarSincronizacao(),
            ),
             MenuCard(
              icon: Icons.credit_card,
              label: 'Assinaturas',
              onTap: () => context.push('/paywall'),
            ),
          ],
        ),
      ),
    );
  }
}