/// lib/features/modules/screens/simple_modules_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Una pantalla de prueba súper simple para aislar la operación de updateUser.
class SimpleModulesScreen extends StatefulWidget {
  final UserModel userModel;
  const SimpleModulesScreen({super.key, required this.userModel});

  @override
  State<SimpleModulesScreen> createState() => _SimpleModulesScreenState();
}

class _SimpleModulesScreenState extends State<SimpleModulesScreen> {
  bool _isLoading = false;

  Future<void> _testActivateModule() async {
    // Si ya estamos cargando, no hacemos nada.
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final firestoreService = context.read<FirestoreService>();
    
    // Hardcodeamos el ID del módulo que queremos añadir para la prueba.
    const moduleIdToTest = 'advanced-finance';

    try {
      print("--- TEST: Intentando activar el módulo '$moduleIdToTest' ---");
      
      await firestoreService.updateUser(widget.userModel.uid, {
        'activeModules': FieldValue.arrayUnion([moduleIdToTest])
      });

      print("--- TEST: ¡Update exitoso! ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡PRUEBA EXITOSA! El módulo se activó.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("--- TEST: ERROR DURANTE EL UPDATE: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PRUEBA FALLIDA: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      print("--- TEST: Bloque 'finally' ejecutado. ---");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Módulos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Usuario: ${widget.userModel.email}'),
            const SizedBox(height: 20),
            Text('Módulos Activos: ${widget.userModel.activeModules.join(', ')}'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _testActivateModule,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Activar "Finanzas Avanzadas"'),
            ),
          ],
        ),
      ),
    );
  }
}