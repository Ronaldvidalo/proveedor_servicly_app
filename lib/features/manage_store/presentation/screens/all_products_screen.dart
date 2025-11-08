import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

/// Esta pantalla mostrará la lista COMPLETA de productos del proveedor,
/// permitiendo una gestión avanzada (búsqueda, filtros, etc.).
class AllProductsScreen extends StatelessWidget {
  final UserModel user;
  const AllProductsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Todos Mis Productos'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // En el futuro, aquí podrás añadir un ícono de búsqueda
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search),
        //     onPressed: () { /* Iniciar búsqueda */ },
        //   ),
        // ],
      ),
      body: const Center(
        child: Text(
          'Aquí irá la lista completa de productos,\ncon búsqueda y filtros.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
      // El FAB para añadir productos también debería vivir aquí
      // (además de en ManageStoreScreen)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a AddEditProductScreen
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}