// lib/pages/bairros/form_bairro_page.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:geo_forest_surveillance/models/bairro_model.dart';
import 'package:geo_forest_surveillance/data/repositories/bairro_repository.dart';

class FormBairroPage extends StatefulWidget {
  final int acaoId;
  final String municipioId;
  final Bairro? bairroParaEditar; 

  const FormBairroPage({
    super.key,
    required this.acaoId,
    required this.municipioId,
    this.bairroParaEditar, 
  });

  bool get isEditing => bairroParaEditar != null;

  @override
  State<FormBairroPage> createState() => _FormBairroPageState();
}

class _FormBairroPageState extends State<FormBairroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _responsavelController = TextEditingController();
  
  final _bairroRepository = BairroRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final b = widget.bairroParaEditar!;
      _nomeController.text = b.nome;
      _responsavelController.text = b.responsavelSetor ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _responsavelController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final bairro = Bairro(
        id: widget.isEditing ? widget.bairroParaEditar!.id : null,
        acaoId: widget.acaoId,
        municipioId: widget.municipioId,
        nome: _nomeController.text.trim(),
        responsavelSetor: _responsavelController.text.trim(),
      );

      try {
        if (widget.isEditing) {
          await _bairroRepository.updateBairro(bairro);
        } else {
          await _bairroRepository.insertBairro(bairro);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bairro ${widget.isEditing ? 'atualizado' : 'adicionado'}!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
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
        title: Text(widget.isEditing ? 'Editar Bairro' : 'Novo Bairro/Setor'),
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
                decoration: const InputDecoration(labelText: 'Nome do Bairro ou Setor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.holiday_village_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O nome é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsavelController,
                decoration: const InputDecoration(labelText: 'Responsável pelo Setor (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvar,
                icon: _isSaving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Bairro'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}