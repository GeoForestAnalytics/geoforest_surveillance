// lib/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionService {
  
  /// Solicita a permissão de armazenamento/fotos e retorna o status final.
  /// O pacote permission_handler lida com as diferentes versões do Android internamente,
  /// tornando a verificação manual de SDKs desnecessária na maioria dos casos.
  Future<PermissionStatus> requestStoragePermission() async {
    Permission permission;

    // Define qual permissão solicitar com base na plataforma.
    // O permission_handler gerencia as complexidades das versões do Android.
    if (Platform.isAndroid) {
      permission = Permission.storage;
    } else if (Platform.isIOS) {
      // Para iOS, a permissão de 'photos' é a correta.
      permission = Permission.photos;
    } else {
      // Plataforma não suportada para esta funcionalidade.
      return PermissionStatus.denied;
    }

    // Solicita a permissão e retorna o status final.
    final status = await permission.request();
    return status;
  }
}