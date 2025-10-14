// lib/models/sync_conflict_model.dart

// Enum para identificar o tipo de dado em conflito
enum ConflictType { foco, diarioDeCampo }

class SyncConflict {
  final ConflictType type;
  final dynamic localData;   // A versão que está no celular (ex: um objeto FocoDengue)
  final dynamic serverData;  // A versão que está na nuvem
  final String identifier;    // Um texto para identificar o item (ex: "Foco: Rua X, 123")

  SyncConflict({
    required this.type,
    required this.localData,
    required this.serverData,
    required this.identifier,
  });
}