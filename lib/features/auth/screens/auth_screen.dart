// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';

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
  /// Clave global para identificar y validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// El modo actual de la pantalla (iniciar sesión o registrarse).
  var _authMode = AuthMode.login;

  /// Controladores para los campos de texto.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Estado para mostrar un indicador de carga durante las operaciones de red.
  var _isLoading = false;

  /// Libera los recursos de los controladores cuando el widget es eliminado.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Cambia entre el modo de inicio de sesión y el de registro.
  void _switchAuthMode() {
    if (_isLoading) return; // No permitir cambiar de modo mientras se carga.
    setState(() {
      _authMode =
          _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _formKey.currentState?.reset();
    });
  }

  /// Intenta enviar los datos del formulario de email/contraseña.
  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isLoading) {
      return;
    }
    _formKey.currentState?.save();

    setState(() => _isLoading = true);

    try {
      if (_authMode == AuthMode.login) {
        // TODO: Llamar a authService.signInWithEmailAndPassword(...)
        // print('Iniciando sesión con: ${_emailController.text}');
      } else {
        // TODO: Llamar a authService.createUserWithEmailAndPassword(...)
        // print('Registrando usuario con: ${_emailController.text}');
      }
      await Future.delayed(const Duration(seconds: 2));
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackbar(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Intenta iniciar sesión con Google.
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // TODO: Llamar a nuestro authService.signInWithGoogle()
      // Esto requerirá el paquete 'google_sign_in'.
      // print('Iniciando sesión con Google...');
      await Future.delayed(const Duration(seconds: 2));
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackbar(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  /// Muestra un SnackBar con un mensaje de error.
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
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
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Ingresa para continuar'
                    : 'Completa los datos para empezar',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- Formulario de Email/Contraseña ---
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Correo Electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@'))
                          return 'Correo inválido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6)
                          return 'La contraseña es muy corta.';
                        return null;
                      },
                    ),
                    if (!isLogin) const SizedBox(height: 16),
                    if (!isLogin)
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                            labelText: 'Confirmar Contraseña'),
                        obscureText: true,
                        validator: (value) {
                          if (value != _passwordController.text)
                            return 'Las contraseñas no coinciden.';
                          return null;
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Botón de Envío Principal ---
              if (_isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ))
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(isLogin ? 'Ingresar' : 'Registrarme'),
                ),
              const SizedBox(height: 24),

              // --- Divisor "O" ---
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

              // --- Botón de Ingreso con Google ---
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.asset('assets/images/google_logo.png',
                    height: 20.0), // Placeholder
                label: const Text('Continuar con Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // --- Botón para cambiar de modo ---
              TextButton(
                onPressed: _switchAuthMode,
                child: Text(
                  isLogin
                      ? '¿No tienes cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Ingresa',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

