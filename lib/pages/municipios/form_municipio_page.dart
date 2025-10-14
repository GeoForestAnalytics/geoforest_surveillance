// lib/pages/municipios/form_municipio_page.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:geo_forest_surveillance/models/municipio_model.dart';
import 'package:geo_forest_surveillance/data/repositories/municipio_repository.dart';

class FormMunicipioPage extends StatefulWidget {
  final int acaoId;
  final Municipio? municipioParaEditar; 

  const FormMunicipioPage({
    super.key,
    required this.acaoId,
    this.municipioParaEditar, 
  });

  bool get isEditing => municipioParaEditar != null;

  @override
  State<FormMunicipioPage> createState() => _FormMunicipioPageState();
}

class _FormMunicipioPageState extends State<FormMunicipioPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nomeController = TextEditingController();
  final _ufController = TextEditingController();
  
  final _municipioRepository = MunicipioRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final m = widget.municipioParaEditar!;
      _idController.text = m.id;
      _nomeController.text = m.nome;
      _ufController.text = m.uf;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nomeController.dispose();
    _ufController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final municipio = Municipio(
        id: _idController.text.trim(),
        acaoId: widget.acaoId,
        nome: _nomeController.text.trim(),
        uf: _ufController.text.trim().toUpperCase(),
      );

      try {
        if (widget.isEditing) {
          await _municipioRepository.updateMunicipio(municipio);
        } else {
          await _municipioRepository.insertMunicipio(municipio);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Município ${widget.isEditing ? 'atualizado' : 'adicionado'}!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError() && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: Este município já foi adicionado a esta ação.'), backgroundColor: Colors.red),
          );
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Município' : 'Adicionar Município'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _idController,
                enabled: !widget.isEditing,
                decoration: InputDecoration(
                  labelText: 'ID do Município (Código IBGE)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  filled: widget.isEditing,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O ID é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Município', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O nome é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ufController,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Estado (UF)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.public_outlined), counterText: ""),
                 validator: (v) => (v == null || v.trim().length != 2) ? 'Informe a sigla (2 letras).' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                icon: _isSaving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Município'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}