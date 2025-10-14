// lib/pages/menu/conflict_resolution_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Imports Adaptados
import 'package:geo_forest_surveillance/models/foco_dengue_model.dart';
import 'package:geo_forest_surveillance/models/sync_conflict_model.dart';
import 'package:geo_forest_surveillance/data/repositories/foco_repository.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';

class ConflictResolutionPage extends StatefulWidget {
  final List<SyncConflict> conflicts;

  const ConflictResolutionPage({super.key, required this.conflicts});

  @override
  State<ConflictResolutionPage> createState() => _ConflictResolutionPageState();
}

class _ConflictResolutionPageState extends State<ConflictResolutionPage> {
  final FocoRepository _focoRepository = FocoRepository();
  late List<SyncConflict> _remainingConflicts;

  @override
  void initState() {
    super.initState();
    _remainingConflicts = List.from(widget.conflicts);
  }

  Future<void> _resolveConflict(SyncConflict conflict, bool keepLocal) async {
    try {
      if (keepLocal) {
        // Para manter a versão local, basta marcá-la como não sincronizada novamente.
        // Na próxima sincronização, ela será enviada para a nuvem, sobrescrevendo a versão do servidor.
        if (conflict.type == ConflictType.foco) {
          final FocoDengue localFoco = conflict.localData;
          final updatedFoco = localFoco.copyWith(isSynced: false);
          await _focoRepository.saveFocoCompleto(updatedFoco);
        }
      } else {
        // Para aceitar a versão do servidor, sobrescrevemos os dados locais.
        if (conflict.type == ConflictType.foco) {
          final FocoDengue serverFoco = conflict.serverData;
          final FocoDengue localFoco = conflict.localData;
          
          // Mantém o ID do banco de dados local, mas atualiza todos os outros dados
          // com a versão do servidor e marca como sincronizado.
          final updatedFoco = serverFoco.copyWith(
            id: localFoco.id,
            isSynced: true, 
          );
          await _focoRepository.saveFocoCompleto(updatedFoco);
        }
      }

      setState(() {
        _remainingConflicts.remove(conflict);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conflito resolvido!'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao resolver conflito: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Conflitos de Sincronização'),
        automaticallyImplyLeading: _remainingConflicts.isEmpty,
      ),
      body: _remainingConflicts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  const SizedBox(height: 16),
                  const Text('Todos os conflitos foram resolvidos!', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar ao Menu'),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _remainingConflicts.length,
              itemBuilder: (context, index) {
                final conflict = _remainingConflicts[index];
                return _buildConflictCard(conflict);
              },
            ),
    );
  }

  Widget _buildConflictCard(SyncConflict conflict) {
    if (conflict.type == ConflictType.foco) {
      final FocoDengue local = conflict.localData;
      final FocoDengue server = conflict.serverData;
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conflict.identifier, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              
              Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: [
                      const Padding(padding: EdgeInsets.all(8), child: Text('Campo', style: TextStyle(fontWeight: FontWeight.bold))),
                      const Padding(padding: EdgeInsets.all(8), child: Text('Sua Versão (Local)', style: TextStyle(fontWeight: FontWeight.bold))),
                      const Padding(padding: EdgeInsets.all(8), child: Text('Versão do Servidor', style: TextStyle(fontWeight: FontWeight.bold))),
                    ]
                  ),
                  _buildComparisonRow('Status', local.statusFoco.name, server.statusFoco.name),
                  _buildComparisonRow('Agente', local.nomeAgente, server.nomeAgente),
                  _buildComparisonRow('Observação', local.observacao ?? '', server.observacao ?? ''),
                ],
              ),

              const SizedBox(height: 20),
              const Text('Qual versão você deseja manter?', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _resolveConflict(conflict, false),
                    child: const Text('Manter do Servidor'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _resolveConflict(conflict, true),
                    child: const Text('Manter a Minha Versão'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Card(child: ListTile(title: Text('Conflito não suportado: ${conflict.identifier}')));
  }

  TableRow _buildComparisonRow(String label, String localValue, String serverValue) {
    final bool isDifferent = localValue != serverValue;
    return TableRow(
      decoration: BoxDecoration(color: isDifferent ? Colors.yellow.shade100 : Colors.transparent),
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(localValue)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(serverValue)),
      ],
    );
  }
}