// lib/pages/menu/splash_page.dart
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // A lógica é a mesma: apenas exibir uma imagem centralizada.
    // Lembre-se de criar um novo logo para o app de vigilância.
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 243, 244),
      body: Center(
        child: Image(
          image: AssetImage('assets/images/logo_3.jpg'), // <-- Troque para o seu novo logo
          width: 280,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}