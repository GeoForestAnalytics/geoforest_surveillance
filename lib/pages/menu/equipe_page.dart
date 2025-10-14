// lib/pages/menu/equipe_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart';

class EquipePage extends StatefulWidget {
  const EquipePage({super.key});

  @override
  State<EquipePage> createState() => _EquipePageState();
}

class _EquipePageState extends State<EquipePage> {
  final _formKey = GlobalKey<FormState>();
  final _liderController = TextEditingController();
  final _ajudantesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preenche os campos com os dados salvos, se existirem.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      _liderController.text = teamProvider.lider ?? '';
      _ajudantesController.text = teamProvider.ajudantes ?? '';
    });
  }
  
  @override
  void dispose() {
    _liderController.dispose();
    _ajudantesController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Usa o provider para salvar os nomes no dispositivo
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      await teamProvider.setTeam(
        _liderController.text.trim(),
        _ajudantesController.text.trim(),
      );

      // O GoRouter, ao ser notificado da mudança no TeamProvider,
      // irá automaticamente redirecionar para a /home.
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificação do Agente'),
        automaticallyImplyLeading: false, // Remove a seta de "voltar"
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_2_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Antes de iniciar a vistoria, por favor, identifique-se.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _liderController,
                  decoration: const InputDecoration(
                    labelText: 'Seu Nome Completo (Agente)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value!.trim().isEmpty
                      ? 'O nome do agente é obrigatório'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ajudantesController,
                  decoration: const InputDecoration(
                    labelText: 'Ajudantes (Opcional)',
                    hintText: 'Ex: João, Maria...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _continuar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(color: Colors.white)
                        )
                      : const Text('Continuar para o Menu'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}