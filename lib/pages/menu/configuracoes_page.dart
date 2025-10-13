// lib/pages/menu/configuracoes_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geo_dengue_monitor/controller/login_controller.dart';
import 'package:geo_dengue_monitor/providers/license_provider.dart';
import 'package:geo_dengue_monitor/services/licensing_service.dart';
import 'package:geo_dengue_monitor/pages/gerente/gerenciar_equipe_page.dart';
import 'package:geo_dengue_monitor/data/repositories/foco_repository.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _focoRepository = FocoRepository();
  final _licensingService = LicensingService();
  
  Map<String, int>? _deviceUsage;
  bool _isLoadingLicense = true;

  @override
  void initState() {
    super.initState();
    _fetchDeviceUsage();
  }
  
  Future<void> _fetchDeviceUsage() async {
    try {
      final usage = await _licensingService.getDeviceUsage();
      if (mounted) {
        setState(() {
          _deviceUsage = usage;
          _isLoadingLicense = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar uso de dispositivos: $e");
      if(mounted) setState(() => _isLoadingLicense = false);
    }
  }

  Future<void> _mostrarDialogoLimpeza({
    required String titulo,
    required String conteudo,
    required VoidCallback onConfirmar,
    bool isDestructive = true,
  }) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(conteudo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
            ),
            child: Text(isDestructive ? 'CONFIRMAR' : 'SAIR'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      onConfirmar();
    }
  }

  Future<void> _handleLogout() async {
    await _mostrarDialogoLimpeza(
      titulo: 'Confirmar Saída',
      conteudo: 'Tem certeza de que deseja sair da sua conta?',
      isDestructive: false,
      onConfirmar: () async {
        await context.read<LoginController>().signOut();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final licenseProvider = context.watch<LicenseProvider>();
    final isGerente = licenseProvider.licenseData?.cargo == 'gerente';

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações e Gerenciamento')),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Conta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _isLoadingLicense
                              ? const Center(child: CircularProgressIndicator())
                              : _deviceUsage == null
                                  ? const Text('Não foi possível carregar os dados da licença.')
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Usuário: ${FirebaseAuth.instance.currentUser?.email ?? 'Desconhecido'}'),
                                        const SizedBox(height: 12),
                                        const Text('Dispositivos Registrados:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(' • Smartphones: ${_deviceUsage!['smartphone']}'),
                                        Text(' • Desktops: ${_deviceUsage!['desktop']}'),
                                      ],
                                    ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(thickness: 1, height: 48),

                  const Text('Gerenciamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                   if (isGerente)
                    Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.groups_outlined, color: Colors.blueAccent),
                        title: const Text('Gerenciar Equipe'),
                        subtitle: const Text('Adicione ou remova agentes.'),
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => const GerenciarEquipePage()));
                        },
                      ),
                    ),

                  const Divider(thickness: 1, height: 48),

                  const Text('Ações Perigosas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                      title: const Text('Limpar TODOS os Focos'),
                      subtitle: const Text('Apaga todos os registros de focos do dispositivo.'),
                      onTap: () => _mostrarDialogoLimpeza(
                        titulo: 'Limpar Todos os Focos',
                        conteudo: 'Tem certeza? TODOS os dados de focos e vistorias serão apagados permanentemente deste dispositivo.',
                        onConfirmar: () async {
                          // TODO: Chamar _focoRepository.limparTodosOsFocos()
                          // await _focoRepository.limparTodosOsFocos();
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos os focos foram apagados!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}