// lib/pages/menu/login_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geo_forest_surveillance/services/auth_service.dart';
import 'package:geo_forest_surveillance/pages/menu/register_page.dart';
import 'package:geo_forest_surveillance/pages/menu/forgot_password_page.dart';

// Cores adaptadas para o tema de saúde
const Color primaryColor = Color(0xFF00838F); // Ciano escuro
const Color secondaryTextColor = Color(0xFF006064);
const Color backgroundColor = Color(0xFFECEFF1); // Cinza azulado claro

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // A navegação agora é controlada pelo AuthCheck no main.dart
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocorreu um erro. Tente novamente.';
       if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') {
        errorMessage = 'Email ou senha inválidos.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Senha incorreta. Por favor, tente novamente.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10),),],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset( 'assets/images/logo_dengue_monitor.png', fit: BoxFit.contain), // <-- Troque para o seu novo logo
                ),
              ),
              const SizedBox(height: 32),
              // Textos
              const Text(
                'Bem-vindo!',
                style: TextStyle( fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acesse o painel de vigilância',
                style: TextStyle(fontSize: 16, color: secondaryTextColor),
              ),
              const SizedBox(height: 40),
              // Formulário
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ... (Campos de email e senha, a lógica interna é a mesma)
                    // Botão de Entrar
                     SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              // ... (Links de "Esqueci minha senha" e "Criar nova conta")
            ],
          ),
        ),
      ),
    );
  }
}