/// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';

/// Define los dos modos posibles de la pantalla de autenticación.
enum AuthMode { login, register }

/// Pantalla para manejar el inicio de sesión y el registro de usuarios.
class AuthScreen extends StatefulWidget {
  /// Constructor para AuthScreen.
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _authMode = AuthMode.login;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    if (_isLoading) return;
    setState(() {
      _authMode =
          _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _formKey.currentState?.reset();
    });
  }

  /// Envía los datos del formulario al AuthService.
  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isLoading) return;
    
    setState(() => _isLoading = true);

    // Obtiene la instancia del AuthService desde el Provider.
    final authService = context.read<AuthService>();

    try {
      if (_authMode == AuthMode.login) {
        await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await authService.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      // La navegación a Home se gestionará automáticamente escuchando el authStateChanges.
    } on FirebaseAuthException catch (error) {
      final errorMessage = _handleAuthException(error);
      _showErrorSnackbar(errorMessage);
    } catch (error) {
      _showErrorSnackbar('Ocurrió un error inesperado. Inténtalo de nuevo.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Llama al método de inicio de sesión con Google del AuthService.
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    
    try {
      await authService.signInWithGoogle();
      // La navegación también se gestionará automáticamente.
    } catch (error) {
      _showErrorSnackbar('No se pudo iniciar sesión con Google. Inténtalo de nuevo.');
    }
    
    if (mounted) setState(() => _isLoading = false);
  }
  
  /// Traduce los códigos de error de FirebaseAuth a mensajes en español.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'email-already-in-use':
        return 'El correo electrónico ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con correo y contraseña no está habilitado.';
      default:
        return 'Ocurrió un error de autenticación.';
    }
  }
  
  /// Muestra un SnackBar con un mensaje de error.
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Título de la pantalla ---
              Text(
                isLogin ? 'Bienvenido de Nuevo' : 'Crea tu Cuenta',
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isLogin ? 'Ingresa para continuar' : 'Completa los datos para empezar',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- Formulario ---
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) return 'Correo inválido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) return 'La contraseña es muy corta.';
                        return null;
                      },
                    ),
                    if (!isLogin) const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      constraints: BoxConstraints(
                        maxHeight: isLogin ? 0 : 100,
                      ),
                      child: !isLogin ? TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Confirmar Contraseña'),
                        obscureText: true,
                        validator: (value) {
                          if (value != _passwordController.text) return 'Las contraseñas no coinciden.';
                          return null;
                        },
                      ) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // --- Botones de Acción ---
              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ))
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(isLogin ? 'Ingresar' : 'Registrarme'),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('O', style: textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.asset('assets/images/google_logo.png', height: 20.0), // Placeholder
                label: const Text('Continuar con Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _switchAuthMode,
                child: Text(
                  isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Ingresa',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}