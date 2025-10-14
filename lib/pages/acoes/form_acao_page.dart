// lib/pages/acoes/form_acao_page.dart

import 'package:flutter/material.dart';
import 'package:geo_forest_surveillance/data/repositories/acao_repository.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';

class FormAcaoPage extends StatefulWidget {
  final int campanhaId;
  final Acao? acaoParaEditar;

  const FormAcaoPage({
    super.key,
    required this.campanhaId,
    this.acaoParaEditar,
  });

  bool get isEditing => acaoParaEditar != null;

  @override
  State<FormAcaoPage> createState() => _FormAcaoPageState();
}

class _FormAcaoPageState extends State<FormAcaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();
  final _descricaoController = TextEditingController();

  final _acaoRepository = AcaoRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final acao = widget.acaoParaEditar!;
      _tipoController.text = acao.tipo;
      _descricaoController.text = acao.descricao ?? '';
    }
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarAcao() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final acao = Acao(
        id: widget.isEditing ? widget.acaoParaEditar!.id : null,
        campanhaId: widget.campanhaId,
        tipo: _tipoController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataCriacao: widget.isEditing ? widget.acaoParaEditar!.dataCriacao : DateTime.now(),
      );

      try {
        if (widget.isEditing) {
          await _acaoRepository.updateAcao(acao);
        } else {
          await _acaoRepository.insertAcao(acao);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ação ${widget.isEditing ? "atualizada" : "criada"} com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
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
        title: Text(widget.isEditing ? 'Editar Ação' : 'Nova Ação/Ciclo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo da Ação',
                  hintText: 'Ex: Visita de Agentes - Ciclo 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'O tipo é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarAcao,
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : (widget.isEditing ? 'Atualizar' : 'Salvar')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}