import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Una pantalla de prueba súper simple para aislar la operación de updateUser.
/// QA FIX: Adaptada para usar el tema dinámico (Claro/Oscuro).
class SimpleModulesScreen extends StatefulWidget {
  final UserModel userModel;
  const SimpleModulesScreen({super.key, required this.userModel});

  @override
  State<SimpleModulesScreen> createState() => _SimpleModulesScreenState();
}

class _SimpleModulesScreenState extends State<SimpleModulesScreen> {
  bool _isLoading = false;

  Future<void> _testActivateModule() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final firestoreService = context.read<FirestoreService>();
    
    // Hardcodeamos el ID del módulo que queremos añadir para la prueba.
    const moduleIdToTest = 'advanced-finance';

    try {
      debugPrint("--- TEST: Intentando activar el módulo '$moduleIdToTest' ---");
      
      await firestoreService.updateUser(widget.userModel.uid, {
        'activeModules': FieldValue.arrayUnion([moduleIdToTest])
      });

      debugPrint("--- TEST: ¡Update exitoso! ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡PRUEBA EXITOSA! El módulo se activó.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("--- TEST: ERROR DURANTE EL UPDATE: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PRUEBA FALLIDA: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      debugPrint("--- TEST: Bloque 'finally' ejecutado. ---");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Prueba de Módulos'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QA FIX: Estilos de texto dinámicos
              Text(
                'Usuario:', 
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6)
                )
              ),
              Text(
                widget.userModel.email ?? 'Sin email',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold
                )
              ),
              
              const SizedBox(height: 30),
              
              Text(
                'Módulos Activos Actuales:',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6)
                )
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor)
                ),
                child: Text(
                  widget.userModel.activeModules.isEmpty 
                      ? "Ninguno" 
                      : widget.userModel.activeModules.join('\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),

              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testActivateModule,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary, // Texto legible sobre el botón
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            color: colorScheme.onPrimary
                          )
                        )
                      : const Text('Activar "Finanzas Avanzadas"'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}