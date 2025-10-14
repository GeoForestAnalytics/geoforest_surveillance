// lib/controller/login_controller.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_forest_surveillance/services/auth_service.dart';
import 'package:geo_forest_surveillance/data/datasources/local/database_helper.dart';

class LoginController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoggedIn = false;
  User? _user;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  bool get isInitialized => _isInitialized;

  LoginController() {
    checkLoginStatus();
  }

  void checkLoginStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _isLoggedIn = false;
        _user = null;
      } else {
        _isLoggedIn = true;
        _user = user;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    try {
      // Limpa o banco de dados local (SQLite)
      await _dbHelper.deleteDatabaseFile();
      
      // Limpa o cache offline do Firestore
      await FirebaseFirestore.instance.clearPersistence();

      // Desloga o usuário do Firebase Auth
      await _authService.signOut();

      // Termina a instância do Firestore para fechar conexões
      await FirebaseFirestore.instance.terminate();

    } catch (e) {
      debugPrint("Erro durante o processo de logout e limpeza: $e");
      // Como medida de segurança, mesmo que a limpeza falhe, ainda tenta deslogar.
      await _authService.signOut();
    }
  }
}