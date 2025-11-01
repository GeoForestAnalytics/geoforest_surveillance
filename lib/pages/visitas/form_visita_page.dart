// Arquivo: lib/pages/visitas/form_visita_page.dart (VERSÃO CORRIGIDA E COMPLETA)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart';

class FormVisitaPage extends StatefulWidget {
  final Imovel imovel;
  final Campanha campanha;
  final Acao acao;
  final Visita? visitaParaEditar;

  const FormVisitaPage({
    super.key,
    required this.imovel,
    required this.campanha,
    required this.acao,
    this.visitaParaEditar,
  });

  bool get isEditing => visitaParaEditar != null;

  @override
  State<FormVisitaPage> createState() => _FormVisitaPageState();
}

class _FormVisitaPageState extends State<FormVisitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _visitaRepository = VisitaRepository();
  bool _isSaving = false;

  // Controladores para campos comuns
  final _nomeResponsavelController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Variáveis de estado para o formulário dinâmico de DENGUE
  StatusFoco? _statusFoco;
  final Set<String> _recipientesSelecionados = {};
  final List<String> _opcoesRecipientes = [
    'Pneu', 'Vaso de Planta', 'Garrafa PET', 'Lixo Acumulado',
    'Caixa d\'água', 'Calha', 'Piscina', 'Laje', 'Outro'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final visita = widget.visitaParaEditar!;
      _nomeResponsavelController.text = visita.nomeResponsavelAtendimento ?? '';
      _observacaoController.text = visita.observacao ?? '';

      // Preenche os dados específicos da dengue se existirem
      if (widget.campanha.tipoCampanha == 'dengue' && visita.dadosFormulario != null) {
        try {
          final data = jsonDecode(visita.dadosFormulario!);
          _statusFoco = StatusFoco.values.firstWhere((e) => e.name == data['statusFoco'], orElse: () => StatusFoco.semFoco);
          if (data['recipientes'] is List) {
            _recipientesSelecionados.addAll(List<String>.from(data['recipientes']));
          }
        } catch (e) {
          debugPrint("Erro ao decodificar dados do formulário de dengue: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeResponsavelController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  String _getTextoStatusFoco(StatusFoco status) {
    switch (status) {
      case StatusFoco.focoEliminado: return 'Foco Eliminado';
      case StatusFoco.potencial: return 'Recipiente Potencial';
      case StatusFoco.tratado: return 'Tratado com Larvicida';
      case StatusFoco.recusado: return 'Visita Recusada';
      case StatusFoco.fechado: return 'Imóvel Fechado';
      case StatusFoco.semFoco: return 'Sem Foco Encontrado';
    }
  }

  Future<void> _salvarVisita() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final agente = context.read<TeamProvider>().lider ?? 'Agente não identificado';

    // Monta o JSON com os dados do formulário específico da campanha
    String? dadosFormularioJson;
    if (widget.campanha.tipoCampanha == 'dengue') {
      final dadosDengue = {
        'statusFoco': _statusFoco?.name,
        'recipientes': _recipientesSelecionados.toList(),
      };
      dadosFormularioJson = jsonEncode(dadosDengue);
    }
    // (Aqui você pode adicionar `else if` para outros tipos de campanha no futuro)

    final visita = Visita(
      id: widget.isEditing ? widget.visitaParaEditar!.id : null,
      uuid: widget.isEditing ? widget.visitaParaEditar!.uuid : null,
      imovelId: widget.imovel.id!,
      campanhaId: widget.campanha.id!,
      acaoId: widget.acao.id!,
      dataVisita: DateTime.now(),
      nomeAgente: agente,
      nomeResponsavelAtendimento: _nomeResponsavelController.text.trim(),
      observacao: _observacaoController.text.trim(),
      dadosFormulario: dadosFormularioJson, // Salva o JSON no campo
    );

    try {
      if (widget.isEditing) {
        await _visitaRepository.updateVisita(visita);
      } else {
        await _visitaRepository.insertVisita(visita);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Visita salva com sucesso!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar visita: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Visita' : 'Registrar Visita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nomeResponsavelController,
                decoration: const InputDecoration(labelText: 'Nome do Responsável (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_search_outlined)),
              ),
              const SizedBox(height: 16),
              
              // =======================================================
              // >> FORMULÁRIO DINÂMICO APARECE AQUI <<
              // =======================================================
              if (widget.campanha.tipoCampanha == 'dengue')
                _buildFormularioDengue(),

              // (Você poderá adicionar outros formulários aqui com `else if`)

              const SizedBox(height: 16),
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(labelText: 'Observações Gerais (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.comment_outlined)),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarVisita,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Visita'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Endereço: ${widget.imovel.logradouro}, ${widget.imovel.numero ?? 'S/N'}', style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 16),
            Text('Campanha: ${widget.campanha.nome}'),
            Text('Ação: ${widget.acao.tipo}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioDengue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dados da Vistoria de Dengue", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 16),
        DropdownButtonFormField<StatusFoco>(
          value: _statusFoco,
          decoration: const InputDecoration(labelText: 'Resultado da Vistoria', border: OutlineInputBorder(), prefixIcon: Icon(Icons.checklist_rtl_outlined)),
          items: StatusFoco.values.map((status) => DropdownMenuItem(value: status, child: Text(_getTextoStatusFoco(status)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _statusFoco = v); },
          validator: (v) => v == null ? 'O resultado da vistoria é obrigatório.' : null,
        ),
        const SizedBox(height: 24),
        Text('Recipientes Encontrados (se houver)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _opcoesRecipientes.map((recipiente) {
              final isSelected = _recipientesSelecionados.contains(recipiente);
              return FilterChip(
                label: Text(recipiente),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _recipientesSelecionados.add(recipiente);
                    } else {
                      _recipientesSelecionados.remove(recipiente);
                    }
                  });
                },
                backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : null,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}