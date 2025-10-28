import 'package:flutter/material.dart';
import 'package:geo_forest_surveillance/models/imovel_model.dart';
import 'package:geo_forest_surveillance/models/campanha_model.dart';
import 'package:geo_forest_surveillance/models/acao_model.dart';
import 'package:geo_forest_surveillance/models/visita_model.dart';
import 'package:geo_forest_surveillance/data/repositories/visita_repository.dart';

class FormVisitaPage extends StatefulWidget {
  final Imovel imovel;
  final Campanha campanha;
  final Acao acao;

  const FormVisitaPage({
    super.key,
    required this.imovel,
    required this.campanha,
    required this.acao,
  });

  @override
  State<FormVisitaPage> createState() => _FormVisitaPageState();
}

class _FormVisitaPageState extends State<FormVisitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _visitaRepository = VisitaRepository();

  // Controladores para os campos do formulário
  final _dataVisitaController = TextEditingController();
  final _nomeAgenteController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _observacaoController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Define a data atual como padrão
    _selectedDate = DateTime.now();
    _dataVisitaController.text = _formatDate(_selectedDate!);
  }

  @override
  void dispose() {
    _dataVisitaController.dispose();
    _nomeAgenteController.dispose();
    _nomeResponsavelController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dataVisitaController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _salvarVisita() async {
    if (_formKey.currentState!.validate()) {
      final visita = Visita(
        imovelId: widget.imovel.id!,
        campanhaId: widget.campanha.id!,
        acaoId: widget.acao.id!,
        dataVisita: _selectedDate!,
        nomeAgente: _nomeAgenteController.text.trim(),
        nomeResponsavelAtendimento:
            _nomeResponsavelController.text.trim().isEmpty
                ? null
                : _nomeResponsavelController.text.trim(),
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
      );

      try {
        await _visitaRepository.insertVisita(visita);
        if (mounted) {
          Navigator.of(context).pop(true); // Retorna true para indicar sucesso
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar visita: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Visita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarVisita,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Informações do imóvel (somente leitura)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imóvel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '${widget.imovel.logradouro}, ${widget.imovel.numero ?? 'S/N'}'),
                      Text('Campanha: ${widget.campanha.nome}'),
                      Text('Ação: ${widget.acao.tipo}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Data da Visita
              TextFormField(
                controller: _dataVisitaController,
                decoration: const InputDecoration(
                  labelText: 'Data da Visita',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a data da visita';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Nome do Agente
              TextFormField(
                controller: _nomeAgenteController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Agente',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome do agente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Nome do Responsável (opcional)
              TextFormField(
                controller: _nomeResponsavelController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Responsável (opcional)',
                ),
              ),
              const SizedBox(height: 16),

              // Campo Observação (opcional)
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
