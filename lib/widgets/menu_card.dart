// lib/widgets/menu_card.dart

import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // <<< 1. CORREÇÃO AQUI: Adicionado '?' para permitir nulo

  const MenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Define a cor do ícone e do texto com base se o card está ativo ou não
    final bool isEnabled = onTap != null;
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = Colors.grey.shade400;

    return Card(
      elevation: isEnabled ? 2.0 : 0.0,
      color: isEnabled ? theme.cardColor : Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, // <<< 2. O InkWell já sabe lidar com um onTap nulo (ele desabilita o clique)
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: isEnabled ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 16.0),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? theme.textTheme.titleMedium?.color : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}