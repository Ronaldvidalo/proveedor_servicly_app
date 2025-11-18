// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proveedor_servicly_app/main.dart'; // Importa tu MyApp

// --- CORRECCIONES DE TEMA ---
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar ProviderScope
import 'package:proveedor_servicly_app/core/services/theme_service.dart'; // Importar ThemeService
import 'package:shared_preferences/shared_preferences.dart'; // Importar SharedPreferences

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    
    // --- CORRECCIÓN DE TEMA ---
    // 1. Simular SharedPreferences para el test
    // (Necesario porque themeService.loadTheme() lo usa)
    SharedPreferences.setMockInitialValues({});
    
    // 2. Crear y cargar el ThemeService
    final themeService = ThemeService();
    await themeService.loadTheme();
    // --- FIN DE CORRECCIÓN ---

    // Build our app and trigger a frame.
    // --- CORRECCIÓN DE CONSTRUCTOR Y PROVIDERSCOPE ---
    await tester.pumpWidget(
      ProviderScope( // 3. Envolver en ProviderScope (como en tu main.dart)
        child: MyApp(themeService: themeService), // 4. Pasar el themeService
      ),
    );
    
    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}