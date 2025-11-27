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
    // QA FIX: Estilos adaptables al tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onTap();
        }
      },
      // QA FIX: Colores explícitos basados en el tema
      selectedColor: colorScheme.primary,
      backgroundColor: theme.cardTheme.color,
      
      // Texto: Blanco/Negro si seleccionado (depende de onPrimary), OnSurface si no
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      
      // Borde: Sin borde si seleccionado, DividerColor si no
      side: isSelected ? BorderSide.none : BorderSide(color: theme.dividerColor),
      
      // Eliminar checkmark para un look más limpio
      showCheckmark: false,
    );
  }
}