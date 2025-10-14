// lib/pages/menu/paywall_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// Modelo para representar um plano.
class PlanoAssinatura {
  final String nome;
  final String descricao;
  final String valorAnual;
  final String valorMensal;
  final IconData icone;
  final Color cor;
  final List<String> features;

  PlanoAssinatura({
    required this.nome,
    required this.descricao,
    required this.valorAnual,
    required this.valorMensal,
    required this.icone,
    required this.cor,
    required this.features,
  });
}

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final List<PlanoAssinatura> planos = [
    PlanoAssinatura(
      nome: "Básico",
      descricao: "Para equipes de campo e municípios pequenos.",
      valorAnual: "R\$ 5.000",
      valorMensal: "R\$ 600",
      icone: Icons.person_outline,
      cor: Colors.blue,
      features: ["3 Agentes de Campo", "Exportação de relatórios", "Suporte padrão"],
    ),
    PlanoAssinatura(
      nome: "Profissional",
      descricao: "Ideal para secretarias de saúde e operações maiores.",
      valorAnual: "R\$ 9.000",
      valorMensal: "R\$ 850",
      icone: Icons.business_center_outlined,
      cor: Colors.green,
      features: ["7 Agentes de Campo", "Painel de Análise (LIRAa)", "Suporte prioritário"],
    ),
    PlanoAssinatura(
      nome: "Premium",
      descricao: "Solução completa para vigilância em larga escala.",
      valorAnual: "R\$ 15.000",
      valorMensal: "R\$ 1.700",
      icone: Icons.star_border_outlined,
      cor: Colors.purple,
      features: ["Agentes ilimitados", "Todos os Módulos", "Compartilhamento de Campanhas"],
    ),
  ];

  Future<void> iniciarContatoWhatsApp(PlanoAssinatura plano, String tipoCobranca) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro: Usuário não logado.")));
      return;
    }

    const String seuNumeroWhatsApp = "5515981409153"; // SUBSTITUA PELO SEU NÚMERO
    
    final String nomePlano = plano.nome;
    final String emailUsuario = user.email ?? "Email não disponível";
    final String mensagem = "Olá! Tenho interesse em contratar o plano *$nomePlano ($tipoCobranca)* para o Geo Dengue Monitor. Meu email de cadastro é: $emailUsuario";
    
    final Uri uri = Uri.parse("https://wa.me/$seuNumeroWhatsApp?text=${Uri.encodeComponent(mensagem)}");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não foi possível abrir o WhatsApp.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Planos e Assinaturas"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Potencialize a Vigilância Epidemiológica",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00838F)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Escolha o plano ideal para as necessidades do seu município.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ...planos.map((plano) => PlanoCard(
                plano: plano,
                onSelecionar: (planoSelecionado, tipoCobranca) => 
                    iniciarContatoWhatsApp(planoSelecionado, tipoCobranca),
              )).toList(),
        ],
      ),
    );
  }
}

class PlanoCard extends StatelessWidget {
  final PlanoAssinatura plano;
  final Function(PlanoAssinatura plano, String tipoCobranca) onSelecionar;

  const PlanoCard({super.key, required this.plano, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: plano.cor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(plano.icone, size: 40, color: plano.cor),
            const SizedBox(height: 12),
            Text(plano.nome, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: plano.cor)),
            const SizedBox(height: 8),
            Text(plano.descricao, style: const TextStyle(fontSize: 15, color: Colors.black54)),
            const Divider(height: 32),
            ...plano.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(child: Text(feature, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onSelecionar(plano, "Mensal"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: plano.cor)),
                    child: Text("${plano.valorMensal}/mês"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onSelecionar(plano, "Anual"),
                    style: ElevatedButton.styleFrom(backgroundColor: plano.cor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text("${plano.valorAnual}/ano"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}