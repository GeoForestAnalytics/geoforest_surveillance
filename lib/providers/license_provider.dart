// lib/providers/license_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geo_forest_surveillance/services/licensing_service.dart';

class LicenseData {
  final String id;
  final String status;
  final DateTime? trialEndDate;
  final Map<String, dynamic> features;
  final Map<String, dynamic> limites;
  final String cargo;

  LicenseData({
    required this.id,
    required this.status,
    this.trialEndDate,
    required this.features,
    required this.limites,
    required this.cargo,
  });
}

class LicenseProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LicensingService _licensingService = LicensingService();

  LicenseData? _licenseData;
  bool _isLoading = true;
  String? _error;

  LicenseData? get licenseData => _licenseData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LicenseProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        fetchLicenseData();
      } else {
        clearLicenseData();
      }
    });
    if (_auth.currentUser != null) {
      fetchLicenseData();
    }
  }

  Future<void> fetchLicenseData() async {
    final user = _auth.currentUser;
    if (user == null) {
      clearLicenseData();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _licensingService.findLicenseDocumentForUser(user);

      if (doc != null && doc.exists) {
        final data = doc.data()!;
        final trialData = data['trial'] as Map<String, dynamic>?;
        
        final usuariosPermitidos = data['usuariosPermitidos'] as Map<String, dynamic>? ?? {};
        final dadosDoUsuario = usuariosPermitidos[user.uid] as Map<String, dynamic>?;
        final cargoDoUsuario = dadosDoUsuario?['cargo'] as String? ?? 'equipe'; // Padrão é 'equipe'

        _licenseData = LicenseData(
          id: doc.id,
          status: data['statusAssinatura'] ?? 'inativa',
          trialEndDate: (trialData?['dataFim'] as Timestamp?)?.toDate(),
          features: data['features'] ?? {},
          limites: data['limites'] ?? {},
          cargo: cargoDoUsuario,
        );
        _error = null;
      } else {
        _error = "Sua conta não está associada a nenhuma licença ativa.";
        _licenseData = null;
      }
    } catch (e) {
      _error = "Erro ao buscar dados da licença: $e";
       _licenseData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearLicenseData() {
    _licenseData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}