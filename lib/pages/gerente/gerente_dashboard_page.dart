import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// TODO: Você precisará criar/adaptar estes providers, seguindo a lógica do GeoForest
// import 'package:geo_dengue_monitor/providers/gerente_provider.dart';
// import 'package:geo_dengue_monitor/providers/dengue_dashboard_filter_provider.dart';
// import 'package:geo_dengue_monitor/providers/dengue_dashboard_metrics_provider.dart';

class GerenteDashboardPage extends StatefulWidget {
  const GerenteDashboardPage({super.key});

  @override
  State<GerenteDashboardPage> createState() => _GerenteDashboardPageState();
}

class _GerenteDashboardPageState extends State<GerenteDashboardPage> {

  @override
  void initState() {
    super.initState();
    // Inicia o carregamento dos dados do gerente assim que a tela é construída
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<GerenteProvider>().iniciarMonitoramento();
    // });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Substitua este conteúdo estático pelo Consumer dos seus providers quando eles forem criados.
    // Exemplo: return Consumer3<GerenteProvider, DengueFilterProvider, DengueMetricsProvider>(
    //   builder: (context, gerente, filter, metrics, child) { ... }
    // );
    
    // Conteúdo de Exemplo enquanto os Providers não existem:
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFiltros(context),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context: context,
            title: 'Progresso Geral',
            value: '75%',
            subtitle: '3.000 de 4.000 imóveis visitados',
            progress: 0.75,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          _buildKpiGrid(context),
          const SizedBox(height: 24),
          _buildRankingAgentesCard(context),
          const SizedBox(height: 24),
          _buildFocosPorStatusCard(context),
        ],
      ),
    );
  }

  // Análogo aos Filtros do GeoForest
  Widget _buildFiltros(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TODO: Substituir por Dropdowns funcionais ligados ao DengueDashboardFilterProvider
            DropdownButtonFormField(items: const [], onChanged: (v){}, decoration: const InputDecoration(labelText: 'Filtrar por Campanha', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField(items: const [], onChanged: (v){}, decoration: const InputDecoration(labelText: 'Período', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField(items: const [], onChanged: (v){}, decoration: const InputDecoration(labelText: 'Agente', border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Análogo ao SummaryCard
  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
  }) {
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
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  // Análogo ao KpiGrid
  Widget _buildKpiGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Focos Positivos', '152', Icons.bug_report, Colors.red)),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Vistorias Totais', '3.000', Icons.home_work, Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Índice de Infestação', '5.1%', Icons.percent, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildKpiCard('Amostras Coletadas', '89', Icons.science, Colors.purple)),
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
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
  
  // Análogo ao Ranking de Equipes
  Widget _buildRankingAgentesCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Top Agentes (Vistorias)", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 40),
              title: const Text('João da Silva', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Text('250 Vistorias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            ListTile(
              leading: const Icon(Icons.military_tech, color: Color(0xFFC0C0C0), size: 40),
              title: const Text('Maria Oliveira', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Text('231 Vistorias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            ListTile(
              leading: const Icon(Icons.military_tech, color: Color(0xFFCD7F32), size: 40),
              title: const Text('Pedro Souza', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Text('215 Vistorias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // Análogo ao Gráfico de Coletas por Atividade
  Widget _buildFocosPorStatusCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Distribuição de Vistorias por Status", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 60, title: '60%', color: Colors.green, titleStyle: const TextStyle(color: Colors.white)),
                    PieChartSectionData(value: 15, title: '15%', color: Colors.red, titleStyle: const TextStyle(color: Colors.white)),
                    PieChartSectionData(value: 10, title: '10%', color: Colors.orange, titleStyle: const TextStyle(color: Colors.white)),
                    PieChartSectionData(value: 15, title: '15%', color: Colors.grey, titleStyle: const TextStyle(color: Colors.white)),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _LegendItem(color: Colors.green, text: 'Sem Foco'),
                _LegendItem(color: Colors.red, text: 'Foco Eliminado'),
                _LegendItem(color: Colors.orange, text: 'Potencial'),
                _LegendItem(color: Colors.grey, text: 'Fechado/Recusado'),
              ],
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