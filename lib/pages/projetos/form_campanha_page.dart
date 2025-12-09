// lib/pages/projetos/form_campanha_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports da Lógica de Dengue
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';

enum TipoProjeto { cadastro, vigilancia }

class FormCampanhaPage extends StatefulWidget {
  final Campanha? campanhaParaEditar;

  const FormCampanhaPage({
    super.key,
    this.campanhaParaEditar,
  });

  bool get isEditing => campanhaParaEditar != null;

  @override
  State<FormCampanhaPage> createState() => _FormCampanhaPageState();
}

class _FormCampanhaPageState extends State<FormCampanhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _campanhaRepository = CampanhaRepository();
  bool _isSaving = false;

  // Controladores
  final _nomeController = TextEditingController();
  final _orgaoController = TextEditingController();
  final _responsavelTecnicoController = TextEditingController();

  // Variáveis de estado
  TipoProjeto _tipoProjetoSelecionado = TipoProjeto.cadastro; // Inicia com "Cadastro" selecionado
  String _tipoVigilanciaSelecionada = 'dengue';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final campanha = widget.campanhaParaEditar!;
      _nomeController.text = campanha.nome;
      _orgaoController.text = campanha.orgaoResponsavel;
      _responsavelTecnicoController.text = campanha.responsavelTecnico ?? '';
      
      if (campanha.tipoCampanha == 'cadastro') {
        _tipoProjetoSelecionado = TipoProjeto.cadastro;
      } else {
        _tipoProjetoSelecionado = TipoProjeto.vigilancia;
        _tipoVigilanciaSelecionada = campanha.tipoCampanha;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _orgaoController.dispose();
    _responsavelTecnicoController.dispose();
    super.dispose();
  }

  Future<void> _salvarCampanha() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final licenseId = context.read<LicenseProvider>().licenseData?.id;
      if (licenseId == null) throw Exception("Licença do usuário não identificada.");

      final String tipoFinal = _tipoProjetoSelecionado == TipoProjeto.cadastro
          ? 'cadastro'
          : _tipoVigilanciaSelecionada;

      final campanha = Campanha(
        id: widget.isEditing ? widget.campanhaParaEditar!.id : null,
        licenseId: widget.isEditing ? widget.campanhaParaEditar!.licenseId : licenseId,
        nome: _nomeController.text.trim(),
        orgaoResponsavel: _orgaoController.text.trim(),
        dataCriacao: widget.isEditing ? widget.campanhaParaEditar!.dataCriacao : DateTime.now(),
        status: widget.isEditing ? widget.campanhaParaEditar!.status : 'ativa',
        tipoCampanha: tipoFinal,
        responsavelTecnico: _responsavelTecnicoController.text.trim(),
        corSetor: null, // Removido da interface
      );
      
      if (widget.isEditing) {
        await _campanhaRepository.updateCampanha(campanha);
      } else {
        await _campanhaRepository.insertCampanha(campanha);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Projeto ${widget.isEditing ? "atualizado" : "criado"} com sucesso!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar projeto: $e'), backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Projeto' : 'Novo Projeto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('1. Tipo de Projeto'),
              SegmentedButton<TipoProjeto>(
                segments: const [
                  ButtonSegment(value: TipoProjeto.vigilancia, label: Text('Vigilância'), icon: Icon(Icons.bug_report_outlined)),
                  ButtonSegment(value: TipoProjeto.cadastro, label: Text('Cadastro'), icon: Icon(Icons.add_home_outlined)),
                ],
                selected: {_tipoProjetoSelecionado},
                onSelectionChanged: (newSelection) => setState(() => _tipoProjetoSelecionado = newSelection.first),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('2. Detalhes do Projeto'),
              
              if (_tipoProjetoSelecionado == TipoProjeto.vigilancia)
                DropdownButtonFormField<String>(
                  value: _tipoVigilanciaSelecionada,
                  decoration: const InputDecoration(labelText: 'Tipo de Vigilância/Inquérito', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'dengue', child: Text('Dengue (Focos)')),
                    DropdownMenuItem(value: 'covid', child: Text('COVID-19')),
                    DropdownMenuItem(value: 'outra', child: Text('Outra Endemia')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _tipoVigilanciaSelecionada = value);
                  },
                ),
              
              if (_tipoProjetoSelecionado == TipoProjeto.vigilancia)
                const SizedBox(height: 16),
              
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Projeto',
                  hintText: _tipoProjetoSelecionado == TipoProjeto.cadastro ? 'Ex: Cadastro Geral 2025' : 'Ex: Campanha Dengue Verão 2025',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.campaign_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O nome é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orgaoController,
                decoration: const InputDecoration(
                  labelText: 'Posto de Saúde / Unidade Responsável',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.corporate_fare_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O órgão é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsavelTecnicoController,
                decoration: const InputDecoration(
                  labelText: 'Responsável Técnico (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarCampanha,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : (widget.isEditing ? 'Atualizar Projeto' : 'Salvar Projeto')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}