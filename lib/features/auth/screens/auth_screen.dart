// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import 'dart:math' as math;

// ... (El enum AuthMode y la clase State completa hasta el método build no cambian)
enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  // ... (Toda tu lógica de initState, dispose, controladores, _submitForm, etc. se mantiene exactamente igual)
  final _formKey = GlobalKey<FormState>();
  var _authMode = AuthMode.login;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut));
    _animationController?.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    if (_isLoading) return;
    setState(() {
      _authMode =
          _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _animationController?.forward(from: 0.0);
    });
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isLoading) return;
    
    setState(() => _isLoading = true);

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
      // CORRECCIÓN: Se eliminó el Navigator. El AuthWrapper se encargará de la navegación.
      
    } on FirebaseAuthException catch (error) {
      final errorMessage = _handleAuthException(error);
      _showErrorSnackbar(errorMessage);
    } catch (error) {
      _showErrorSnackbar('Ocurrió un error inesperado. Inténtalo de nuevo.');
    }

    // El `setState` en el `finally` es importante para detener el spinner si hay un error.
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    
    try {
      await authService.signInWithGoogle();
      // CORRECCIÓN: Se eliminó el Navigator. El AuthWrapper se encargará de la navegación.

    } catch (error) {
      _showErrorSnackbar('No se pudo iniciar sesión con Google. Inténtalo de nuevo.');
    }
    
    if (mounted) setState(() => _isLoading = false);
  }
  
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
  
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;
    final textTheme = Theme.of(context).textTheme;

    const primaryColor = Color(0xFF00BFFF);
    const backgroundColor = Color(0xFF1A1A2E);
    const surfaceColor = Color(0xFF2D2D5A);
    const textColor = Colors.white;

    if (_fadeAnimation == null) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          // --- INICIO DE LA MODIFICACIÓN RESPONSIVA ---
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), // Ancho máximo para el formulario
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo de la App ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield_moon_rounded,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // ... Todo el resto de tu código de la Column se mantiene intacto ...
                // AnimatedSwitcher para el título, Form, botones, etc.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    isLogin ? 'Bienvenido de Nuevo' : 'Crea tu Cuenta',
                    key: ValueKey(_authMode),
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Ingresa para continuar' : 'Completa los datos para empezar',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        _buildConfirmPasswordField(isLogin),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSubmitButton(isLogin, primaryColor, textColor),
                const SizedBox(height: 24),
                _buildDivider(textTheme),
                const SizedBox(height: 24),
                _buildGoogleSignInButton(surfaceColor),
                const SizedBox(height: 16),
                _buildSwitchAuthModeButton(isLogin, primaryColor),
              ],
            ),
          ),
          // --- FIN DE LA MODIFICACIÓN RESPONSIVA ---
        ),
      ),
    );
  }

  // --- Tus widgets refactorizados (_buildEmailField, _buildPasswordField, etc.) se mantienen exactamente igual ---
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _buildInputDecoration(
        labelText: 'Correo Electrónico',
        prefixIcon: Icons.alternate_email_rounded,
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || !value.contains('@') || !value.contains('.')) return 'Correo inválido.';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: _buildInputDecoration(
        labelText: 'Contraseña',
        prefixIcon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white70,
          ),
          onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      obscureText: _isPasswordObscured,
      validator: (value) {
        if (value == null || value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(bool isLogin) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: isLogin
          ? const SizedBox.shrink()
          : TextFormField(
              controller: _confirmPasswordController,
              decoration: _buildInputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: _isConfirmPasswordObscured,
              validator: (value) {
                if (_authMode == AuthMode.register && value != _passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }
                return null;
              },
            ),
    );
  }

  Widget _buildSubmitButton(bool isLogin, Color primaryColor, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _submitForm,
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: Colors.black,
        ),
        child: _isLoading
            ?  SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: textColor,
                ),
              )
            : Text(
                isLogin ? 'Ingresar' : 'Registrarme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(TextTheme textTheme) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text('O', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ),
        const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
      ],
    );
  }
  
  Widget _buildGoogleSignInButton(Color surfaceColor) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: const GoogleLogo(),
        label: const Text(
          'Continuar con Google',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSwitchAuthModeButton(bool isLogin, Color primaryColor) {
    return TextButton(
      onPressed: _isLoading ? null : _switchAuthMode,
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text.rich(
        TextSpan(
          text: isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
          style: const TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: isLogin ? 'Regístrate' : 'Ingresa',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    const primaryColor = Color(0xFF00BFFF);
    const surfaceColor = Color.fromARGB(255, 34, 34, 68);
    
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(prefixIcon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CustomPaint(
            painter: _GoogleLogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width / 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 0.9, false, paint..color = colors[0]);
    canvas.drawArc(rect, math.pi * 0.4, math.pi * 0.6, false, paint..color = colors[1]);
    canvas.drawArc(rect, math.pi, math.pi * 0.5, false, paint..color = colors[2]);
    canvas.drawArc(rect, math.pi * 1.5, math.pi * 0.6, false, paint..color = colors[3]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}