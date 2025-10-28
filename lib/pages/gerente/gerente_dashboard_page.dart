// lib/pages/gerente/gerente_dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import 'package:geo_forest_surveillance/providers/gerente_provider.dart';
import 'package:geo_forest_surveillance/providers/dashboard_filter_provider.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';

/// Classe auxiliar para calcular e armazenar as métricas do dashboard.
class _DashboardMetrics {
  final int totalImoveis;
  final int totalVisitas;
  final int focosPositivos;
  final double progressoGeral;
  final Map<String, int> rankingAgentes;
  final Map<StatusFoco, int> distribuicaoStatus;

  _DashboardMetrics({
    this.totalImoveis = 0,
    this.totalVisitas = 0,
    this.focosPositivos = 0,
    this.progressoGeral = 0.0,
    this.rankingAgentes = const {},
    this.distribuicaoStatus = const {},
  });

  factory _DashboardMetrics.fromProviders(GerenteProvider gProvider, DashboardFilterProvider fProvider) {
    // Aplica os filtros aos dados brutos
    final List<Visita> visitasFiltradas = gProvider.visitasSincronizadas.where((visita) {
      final campanhaOk = fProvider.campanhaSelecionada == null || visita.campanhaId == fProvider.campanhaSelecionada!.id;
      final agenteOk = fProvider.agenteSelecionado == null || visita.nomeAgente == fProvider.agenteSelecionado;
      final periodoOk = fProvider.periodoSelecionado == null ||
          (visita.dataVisita.isAfter(fProvider.periodoSelecionado!.start) &&
           visita.dataVisita.isBefore(fProvider.periodoSelecionado!.end.add(const Duration(days: 1))));
      return campanhaOk && agenteOk && periodoOk;
    }).toList();

    // Métricas de Dengue
    int focosPositivosCount = 0;
    final statusCounts = <StatusFoco, int>{};

    final visitasDengue = visitasFiltradas.where((v) {
      final campanha = gProvider.campanhas.firstWhereOrNull((c) => c.id == v.campanhaId);
      return campanha?.tipoCampanha == 'dengue';
    }).toList();

    for (var visita in visitasDengue) {
      if (visita.dadosFormulario != null) {
        try {
          final data = jsonDecode(visita.dadosFormulario!);
          final statusString = data['statusFoco'];
          final status = StatusFoco.values.firstWhere((e) => e.name == statusString);
          statusCounts.update(status, (value) => value + 1, ifAbsent: () => 1);
          if (status == StatusFoco.focoEliminado || status == StatusFoco.tratado) {
            focosPositivosCount++;
          }
        } catch (_) {}
      }
    }

    // Ranking de Agentes
    final agentCounts = groupBy(visitasFiltradas, (Visita v) => v.nomeAgente)
        .map((key, value) => MapEntry(key, value.length));

    // Progresso Geral (considera todos os imóveis, mas apenas as visitas filtradas)
    int totalImoveis = gProvider.imoveisSincronizados.length;
    double progresso = (totalImoveis == 0) ? 0.0 : visitasFiltradas.length / totalImoveis;
    if (progresso.isNaN || progresso.isInfinite) progresso = 0.0;

    return _DashboardMetrics(
      totalImoveis: totalImoveis,
      totalVisitas: visitasFiltradas.length,
      focosPositivos: focosPositivosCount,
      progressoGeral: progresso,
      rankingAgentes: agentCounts,
      distribuicaoStatus: statusCounts,
    );
  }
}


class GerenteDashboardPage extends StatefulWidget {
  const GerenteDashboardPage({super.key});

  @override
  State<GerenteDashboardPage> createState() => _GerenteDashboardPageState();
}

class _GerenteDashboardPageState extends State<GerenteDashboardPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GerenteProvider>().iniciarMonitoramento();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<GerenteProvider, DashboardFilterProvider>(
        builder: (context, gProvider, fProvider, child) {
          if (gProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (gProvider.error != null) {
            return Center(child: Text("Erro ao carregar dados: ${gProvider.error}"));
          }

          final metrics = _DashboardMetrics.fromProviders(gProvider, fProvider);
          
          return RefreshIndicator(
            onRefresh: () => gProvider.iniciarMonitoramento(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildFiltros(context, gProvider, fProvider),
                const SizedBox(height: 16),
                _buildSummaryCard(context: context, metrics: metrics),
                const SizedBox(height: 24),
                _buildKpiGrid(context, metrics: metrics),
                const SizedBox(height: 24),
                _buildRankingAgentesCard(context, metrics: metrics),
                const SizedBox(height: 24),
                _buildFocosPorStatusCard(context, metrics: metrics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltros(BuildContext context, GerenteProvider gProvider, DashboardFilterProvider fProvider) {
    final agentes = gProvider.visitasSincronizadas.map((v) => v.nomeAgente).toSet().toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<Campanha>(
              value: fProvider.campanhaSelecionada,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Filtrar por Campanha', border: OutlineInputBorder()),
              items: gProvider.campanhas.map((campanha) {
                return DropdownMenuItem(value: campanha, child: Text(campanha.nome, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (v) => fProvider.setCampanha(v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: fProvider.agenteSelecionado,
                    decoration: const InputDecoration(labelText: 'Agente', border: OutlineInputBorder()),
                    items: agentes.map((agente) => DropdownMenuItem(value: agente, child: Text(agente))).toList(),
                    onChanged: (v) => fProvider.setAgente(v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (range != null) fProvider.setPeriodo(range);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Período', border: OutlineInputBorder()),
                      child: Text(fProvider.periodoSelecionado == null 
                          ? 'Todos' 
                          : '${DateFormat('dd/MM/yy').format(fProvider.periodoSelecionado!.start)} - ${DateFormat('dd/MM/yy').format(fProvider.periodoSelecionado!.end)}'),
                    ),
                  ),
                ),
              ],
            ),
            if (fProvider.campanhaSelecionada != null || fProvider.agenteSelecionado != null || fProvider.periodoSelecionado != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: fProvider.limparFiltros, child: const Text('Limpar Filtros')),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({ required BuildContext context, required _DashboardMetrics metrics }) {
     return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progresso Geral', style: Theme.of(context).textTheme.titleLarge),
                Text('${(metrics.progressoGeral * 100).toStringAsFixed(1)}%', 
                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${metrics.totalVisitas} visitas em ${metrics.totalImoveis} imóveis cadastrados', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: metrics.progressoGeral > 1.0 ? 1.0 : metrics.progressoGeral, // Garante que não passe de 100%
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, { required _DashboardMetrics metrics }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Focos Positivos', metrics.focosPositivos.toString(), Icons.bug_report, Colors.red)),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Vistorias Totais', metrics.totalVisitas.toString(), Icons.home_work, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRankingAgentesCard(BuildContext context, { required _DashboardMetrics metrics }) {
    final rankingOrdenado = metrics.rankingAgentes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top3 = rankingOrdenado.take(3).toList();
    final icones = [
      const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 40),
      const Icon(Icons.military_tech, color: Color(0xFFC0C0C0), size: 40),
      const Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 40),
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Top Agentes (Vistorias)", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (top3.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('Nenhuma visita encontrada com os filtros atuais.'),
              ))
            else
              ...List.generate(top3.length, (index) {
                final entry = top3[index];
                return ListTile(
                  leading: icones[index],
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('${entry.value} Vistorias', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFocosPorStatusCard(BuildContext context, { required _DashboardMetrics metrics }) {
    final Map<StatusFoco, Color> cores = {
      StatusFoco.semFoco: Colors.green,
      StatusFoco.focoEliminado: Colors.red,
      StatusFoco.tratado: Colors.red.shade700,
      StatusFoco.potencial: Colors.orange,
      StatusFoco.fechado: Colors.grey,
      StatusFoco.recusado: Colors.grey.shade700,
    };
    final Map<StatusFoco, String> legendas = {
      StatusFoco.semFoco: 'Sem Foco',
      StatusFoco.focoEliminado: 'Foco Eliminado',
      StatusFoco.tratado: 'Foco Tratado',
      StatusFoco.potencial: 'Potencial',
      StatusFoco.fechado: 'Fechado',
      StatusFoco.recusado: 'Recusado',
    };

    final total = metrics.distribuicaoStatus.values.fold(0, (prev, e) => prev + e);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Distribuição de Vistorias (Dengue)", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            if (total == 0)
              const SizedBox(height: 200, child: Center(child: Text('Nenhuma visita de dengue encontrada com os filtros atuais.')))
            else
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: metrics.distribuicaoStatus.entries.map((entry) {
                      final porcentagem = (entry.value / total) * 100;
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '${porcentagem.toStringAsFixed(0)}%',
                        color: cores[entry.key] ?? Colors.blueGrey,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        radius: 80,
                      );
                    }).toList(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: metrics.distribuicaoStatus.entries
                  .map((entry) => _LegendItem(color: cores[entry.key]!, text: legendas[entry.key]!))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}