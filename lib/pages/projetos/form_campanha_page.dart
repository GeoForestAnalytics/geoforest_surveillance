// lib/pages/projetos/form_campanha_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports atualizados para a lógica de Dengue
import 'package:geo_forest_surveillance/data/repositories/campanha_repository.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';


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
  final _nomeController = TextEditingController();
  final _orgaoResponsavelController = TextEditingController();

  final _campanhaRepository = CampanhaRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final campanha = widget.campanhaParaEditar!;
      _nomeController.text = campanha.nome;
      _orgaoResponsavelController.text = campanha.orgaoResponsavel;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _orgaoResponsavelController.dispose();
    super.dispose();
  }

  Future<void> _salvarCampanha() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final licenseProvider = context.read<LicenseProvider>();
        final licenseId = licenseProvider.licenseData?.id;

        if (licenseId == null) {
          throw Exception("Não foi possível identificar a licença do usuário.");
        }

        final campanha = Campanha(
          id: widget.isEditing ? widget.campanhaParaEditar!.id : null,
          licenseId: licenseId,
          nome: _nomeController.text.trim(),
          orgaoResponsavel: _orgaoResponsavelController.text.trim(),
          dataCriacao: widget.isEditing ? widget.campanhaParaEditar!.dataCriacao : DateTime.now(),
          status: widget.isEditing ? widget.campanhaParaEditar!.status : 'ativa',
        );
        
        if (widget.isEditing) {
          await _campanhaRepository.updateCampanha(campanha);
        } else {
          await _campanhaRepository.insertCampanha(campanha);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Campanha ${widget.isEditing ? "atualizada" : "criada"} com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna 'true' para indicar sucesso
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar campanha: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Campanha' : 'Nova Campanha'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Campanha',
                  hintText: 'Ex: Campanha de Verão 2025',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.campaign_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome da campanha é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orgaoResponsavelController,
                decoration: const InputDecoration(
                  labelText: 'Órgão Responsável',
                  hintText: 'Ex: Secretaria de Saúde do Município',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.corporate_fare_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O órgão responsável é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarCampanha,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : (widget.isEditing ? 'Atualizar Campanha' : 'Salvar Campanha')),
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
}