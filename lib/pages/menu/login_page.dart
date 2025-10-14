// lib/pages/menu/login_page.dart

import 'package:flutter/foundation.dart'; // Import necessário para 'kDebugMode'
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_forest_surveillance/services/auth_service.dart';
import 'package:geo_forest_surveillance/pages/menu/register_page.dart';
import 'package:geo_forest_surveillance/pages/menu/forgot_password_page.dart';

// Cores
const Color primaryColor = Color(0xFF00838F);
const Color secondaryTextColor = Color(0xFF006064);
const Color backgroundColor = Color(0xFFECEFF1);

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
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocorreu um erro.';
      if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') {
        errorMessage = 'Email ou senha inválidos.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Senha incorreta.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // <<< FUNÇÃO ADICIONADA AQUI >>>
  /// Tenta fazer login com credenciais de teste pré-definidas.
  Future<void> _loginTeste() async {
    setState(() => _isLoading = true);
    try {
      // IMPORTANTE: Substitua com um email e senha de um usuário de teste
      // que você criou no Firebase Authentication.
      await _authService.signInWithEmailAndPassword(
        email: 'teste@exemplo.com',
        password: '123456',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login de teste: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // <<< FIM DA ADIÇÃO >>>


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
              Container(
                width: 120, height: 120, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10),)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/logo_3.jpeg', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Bem-vindo!', style: TextStyle( fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              const Text('Acesse o painel de vigilância', style: TextStyle(fontSize: 16, color: secondaryTextColor)),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Insira um email válido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        )
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'A senha deve ter no mínimo 6 caracteres' : null,
                    ),
                    
                    // <<< BOTÃO DE TESTE ADICIONADO AQUI >>>
                    if (kDebugMode)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _isLoading ? null : _loginTeste,
                          child: const Text('Login Teste (Dev)', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Entrar', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Não tem uma conta?'),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Crie uma agora'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}