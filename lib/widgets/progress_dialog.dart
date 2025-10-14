// lib/widgets/progress_dialog.dart

import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String message;

  const ProgressDialog({super.key, required this.message});

  /// Mostra o diálogo de progresso.
  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede que o usuário feche o diálogo com um toque fora
      builder: (BuildContext context) {
        return PopScope( // Impede que o botão "Voltar" do Android feche o diálogo
          canPop: false,
          child: ProgressDialog(message: message),
        );
      },
    );
  }

  /// Esconde o diálogo de progresso.
  static void hide(BuildContext context) {
    // Garante que o diálogo só é fechado se ainda estiver na tela
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      ),
    );
  }
}