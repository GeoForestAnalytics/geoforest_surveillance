// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geo_forest_surveillance/services/licensing_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LicensingService _licensingService = LicensingService();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }
      
      // Verifica a licença e registra o dispositivo após o login bem-sucedido
      await _licensingService.checkAndRegisterDevice(user);
      
      await user.getIdToken(true); 
      
      return userCredential;
  
    } on LicenseException {
      // Se houver erro de licença, desloga o usuário e repassa o erro
      await signOut(); 
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(displayName);

        final trialEndDate = DateTime.now().add(const Duration(days: 7));
        
        // Estrutura da licença para um novo cliente (gerente)
        final licenseData = {
          'statusAssinatura': 'trial',
          'features': {'exportacao': true, 'analise': true}, // Funcionalidades padrão no trial
          'limites': {'smartphone': 3, 'desktop': 1},
          'trial': {
            'ativo': true,
            'dataInicio': FieldValue.serverTimestamp(),
            'dataFim': Timestamp.fromDate(trialEndDate),
          },
          'uidsPermitidos': [user.uid],
          'usuariosPermitidos': {
            user.uid: {
              'cargo': 'gerente',
              'nome': displayName,
              'email': email,
              'adicionadoEm': FieldValue.serverTimestamp(),
            }
          }
        };

        // Usa um batch para garantir que ambas as escritas aconteçam juntas
        final batch = _firestore.batch();
        final clienteDocRef = _firestore.collection('clientes').doc(user.uid);
        batch.set(clienteDocRef, licenseData);

        final userDocRef = _firestore.collection('users').doc(user.uid);
        batch.set(userDocRef, {'email': email, 'licenseId': user.uid});

        await batch.commit();
      }
      
      return credential;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Este email já está em uso por outra conta.');
      }
      throw Exception('Ocorreu um erro durante o registro: ${e.message}');
    }
  }
  
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;
}