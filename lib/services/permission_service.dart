// lib/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  
  /// Solicita a permissão de armazenamento/fotos de forma robusta para diferentes versões do Android e iOS.
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      
      // Android 13+ (SDK 33)
      if (deviceInfo.version.sdkInt >= 33) {
        var photoStatus = await Permission.photos.status;
        if (!photoStatus.isGranted) {
          photoStatus = await Permission.photos.request();
        }
        return photoStatus.isGranted;
      } 
      // Android 11 e 12 (SDK 30-32)
      else if (deviceInfo.version.sdkInt >= 30) {
        var storageStatus = await Permission.manageExternalStorage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.manageExternalStorage.request();
        }
        return storageStatus.isGranted;
      } 
      // Android 10 e inferior
      else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    } else {
      // Para iOS
      var status = await Permission.photos.request();
      return status.isGranted;
    }
  }
}