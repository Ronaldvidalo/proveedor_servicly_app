import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Usaremos ChoiceChip, que maneja bien el estado seleccionado/no seleccionado
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Solo llamamos a onTap si el chip está siendo seleccionado (selected == true)
        // Esto evita llamadas innecesarias si se toca el chip ya seleccionado.
        if (selected) {
          onTap();
        }
      },
      // Puedes personalizar colores aquí si quieres
      // selectedColor: Theme.of(context).colorScheme.primaryContainer,
      // labelStyle: TextStyle(color: isSelected ? Colors.black : null),
    );
  }
}