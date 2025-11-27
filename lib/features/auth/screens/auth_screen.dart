// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 18/10/2025
// Style: Cyber Glow (Adaptive Light/Dark)
// QA FIX 26/11/2025:
// 1. Refactorización completa para soportar Modo Claro/Oscuro usando ThemeService.
// 2. Lógica de seguridad (Bloqueo, Regex, Validación) preservada.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/services/auth_service.dart';

enum AuthMode { login, register, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  var _authMode = AuthMode.login;
  
  // Controladores
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Estado UI
  var _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  AnimationController? _animationController;

  // --- VARIABLES DE SEGURIDAD ---
  int _failedLoginAttempts = 0;
  DateTime? _lockoutTime;
  static const int _maxAttempts = 3;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
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

  // --- LOGICA DE BLOQUEO DE SEGURIDAD ---
  bool _checkLockout() {
    if (_lockoutTime != null) {
      if (DateTime.now().isBefore(_lockoutTime!)) {
        final remaining = _lockoutTime!.difference(DateTime.now()).inMinutes;
        _showErrorSnackbar('Cuenta bloqueada por seguridad. Intenta en ${remaining + 1} minutos.');
        return true; 
      } else {
        setState(() {
          _lockoutTime = null;
          _failedLoginAttempts = 0;
        });
      }
    }
    return false; 
  }

  void _handleFailedAttempt() {
    setState(() {
      _failedLoginAttempts++;
    });

    if (_failedLoginAttempts >= _maxAttempts) {
      setState(() {
        _lockoutTime = DateTime.now().add(_lockoutDuration);
      });
      _showErrorSnackbar('Has excedido los intentos permitidos. Cuenta bloqueada temporalmente.');
    } else {
       _showErrorSnackbar('Contraseña incorrecta. Intentos restantes: ${_maxAttempts - _failedLoginAttempts}');
    }
  }

  void _switchAuthMode(AuthMode newMode) {
    if (_isLoading) return;
    setState(() {
      _authMode = newMode;
      _formKey.currentState?.reset();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _animationController?.forward(from: 0.0);
    });
  }

  Future<void> _submitForm() async {
    if (_checkLockout()) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isLoading) return;

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final firebaseAuth = FirebaseAuth.instance;

    try {
      if (_authMode == AuthMode.login) {
        // --- LOGIN ---
        await authService.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim());
        
        setState(() {
          _failedLoginAttempts = 0;
          _lockoutTime = null;
        });

      } else if (_authMode == AuthMode.register) {
        // --- REGISTRO ---
        await authService.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

      } else if (_authMode == AuthMode.forgotPassword) {
        // --- RECUPERACIÓN ---
        final email = _emailController.text.trim();
        final signInMethods = await firebaseAuth.fetchSignInMethodsForEmail(email);

        if (signInMethods.isEmpty) {
          if (mounted) {
             setState(() => _isLoading = false);
             _showUserNotFoundDialog();
          }
          return;
        }

        await authService.sendPasswordResetEmail(email: email);
        
        messenger.showSnackBar(SnackBar(
          content: Text('✔ Enlace enviado. Revisa tu correo.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ));
        
        _switchAuthMode(AuthMode.login);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'wrong-password' && _authMode == AuthMode.login) {
        _handleFailedAttempt();
      } else {
        _showErrorSnackbar(_handleAuthException(error));
      }
    } catch (error) {
      _showErrorSnackbar('Ocurrió un error inesperado. Inténtalo de nuevo.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --- UI HELPERS ADAPTATIVOS ---

  void _showUserNotFoundDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // QA FIX: Fondo dinámico (Blanco en Claro, Azul en Oscuro)
        backgroundColor: theme.cardTheme.color,
        title: Text("Usuario no encontrado", 
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          "Este correo no está registrado en nuestra base de datos. ¿Deseas crear una cuenta nueva?",
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancelar", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _switchAuthMode(AuthMode.register);
            },
            // El color primario (Neón) se mantiene
            style: FilledButton.styleFrom(backgroundColor: theme.primaryColor),
            child: Text("Registrarme", style: TextStyle(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Credenciales incorrectas.';
      case 'email-already-in-use':
        return 'El correo ya está registrado.';
      case 'invalid-email':
        return 'Formato de correo inválido.';
      case 'weak-password':
        return 'Contraseña muy débil (min 6 caracteres).';
      default:
        return 'Error: ${e.code}';
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.security, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    try {
      await authService.signInWithGoogle();
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackbar('No se pudo iniciar sesión con Google.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;
    final isRegister = _authMode == AuthMode.register;
    final isForgotPassword = _authMode == AuthMode.forgotPassword;
    
    // --- QA FIX: OBTENER TEMA DEL CONTEXTO ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // 1. Fondo dinámico (Gris claro / Azul Oscuro)
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(isLogin, isRegister, isForgotPassword, theme),
                  
                  const SizedBox(height: 32), 

                  _buildFormFields(isForgotPassword, isLogin, theme),

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => _switchAuthMode(AuthMode.forgotPassword),
                        child: Text('¿Olvidaste tu contraseña?', 
                            // Texto usa color primario (Neón)
                            style: TextStyle(color: colorScheme.primary)),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  _buildSubmitButton(isLogin, isRegister, theme),
                  
                  if (!isForgotPassword) ...[
                    const SizedBox(height: 24),
                    _buildDivider(theme),
                    const SizedBox(height: 24),
                    _buildGoogleSignInButton(theme),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildSwitchAuthModeButton(isLogin, isForgotPassword, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN ADAPTADOS ---

  Widget _buildFormFields(
      bool isForgotPassword, bool isLogin, ThemeData theme) {
    
    // Obtenemos colores directamente del tema para los inputs
    // En nuestro AppThemes, inputDecorationTheme ya tiene fillColor definido
    final textColor = theme.colorScheme.onSurface; 

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            // Texto del input dinámico (Negro en Light / Blanco en Dark)
            style: TextStyle(color: textColor),
            decoration: _getAdaptiveInputDecoration(
              theme,
              labelText: 'Correo Electrónico',
              prefixIcon: Icons.alternate_email_rounded,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'El correo es obligatorio.';
              final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(value)) {
                return 'Formato de correo inválido.';
              }
              return null;
            },
          ),
          if (!isForgotPassword) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: TextStyle(color: textColor),
              decoration: _getAdaptiveInputDecoration(
                theme,
                labelText: 'Contraseña',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      // Icono gris adaptable
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  onPressed: () =>
                      setState(() => _isPasswordObscured = !_isPasswordObscured),
                ),
              ),
              obscureText: _isPasswordObscured,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Mínimo 6 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildConfirmPasswordField(isLogin || isForgotPassword, theme),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField(bool isHidden, ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: isHidden
          ? const SizedBox.shrink()
          : TextFormField(
              controller: _confirmPasswordController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: _getAdaptiveInputDecoration(
                theme,
                labelText: 'Confirmar Contraseña',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                      _isConfirmPasswordObscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  onPressed: () => setState(() =>
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                ),
              ),
              obscureText: _isConfirmPasswordObscured,
              validator: (value) {
                if (_authMode == AuthMode.register &&
                    value != _passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }
                return null;
              },
            ),
    );
  }

  Widget _buildHeader(bool isLogin, bool isRegister, bool isForgotPassword, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // QA FIX: Fondo del logo adaptable (Blanco en light / Azul Oscuro en dark)
            color: theme.cardTheme.color, 
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/servicly_logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 32),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            isLogin
                ? 'Bienvenido de Nuevo'
                : (isRegister ? 'Crea tu Cuenta' : 'Recuperar Contraseña'),
            key: ValueKey(_authMode),
            // QA FIX: Usar textTheme para color automático
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLogin
              ? 'Ingresa para continuar'
              : (isRegister ? 'Ingresa tu correo y contraseña' : 'Ingresa tu correo para validar tu cuenta'),
          // QA FIX: Texto secundario adaptable
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isLogin, bool isRegister, ThemeData theme) {
    String buttonText = isLogin ? 'Ingresar' : (isRegister ? 'Registrarme' : 'Enviar Enlace');

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _submitForm,
        // El estilo FilledButton ya viene configurado en AppTheme
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 3, 
                    // Color contraste (Negro sobre neón suele ser mejor)
                    color: theme.colorScheme.onPrimary))
            : Text(buttonText,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary)),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    final dividerColor = theme.dividerColor;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text('O',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: const GoogleLogo(),
        label: Text('Continuar con Google',
            // Texto visible en ambos modos
            style: TextStyle(
                color: theme.colorScheme.onSurface, 
                fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.dividerColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSwitchAuthModeButton(bool isLogin, bool isForgotPassword, ThemeData theme) {
    if (isForgotPassword) {
      return TextButton.icon(
        onPressed: _isLoading ? null : () => _switchAuthMode(AuthMode.login),
        icon: Icon(Icons.arrow_back_ios_new, size: 16, color: theme.colorScheme.onSurface),
        label: Text('Volver a Ingresar', style: TextStyle(color: theme.colorScheme.onSurface)),
      );
    }

    return TextButton(
      onPressed: _isLoading
          ? null
          : () => _switchAuthMode(isLogin ? AuthMode.register : AuthMode.login),
      style: TextButton.styleFrom(
        foregroundColor: theme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text.rich(
        TextSpan(
          text: isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          children: [
            TextSpan(
              text: isLogin ? 'Regístrate' : 'Ingresa',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para generar decoración usando el tema actual
  InputDecoration _getAdaptiveInputDecoration(ThemeData theme, {
    String? labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    // Tomamos la base del tema (que ya tiene colores correctos)
    return InputDecoration(
      labelText: labelText,
      // Icono prefijo usa el color de texto secundario
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.inputDecorationTheme.labelStyle?.color) : null,
      suffixIcon: suffixIcon,
      // Forzamos el uso del tema definido en AppThemes
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
    );
  }
}

// --- WIDGETS AUXILIARES ---

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white, // El logo de Google siempre lleva fondo blanco
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
    canvas.drawArc(
        rect, -math.pi / 2, math.pi * 0.9, false, paint..color = colors[0]);
    canvas.drawArc(
        rect, math.pi * 0.4, math.pi * 0.6, false, paint..color = colors[1]);
    canvas.drawArc(
        rect, math.pi, math.pi * 0.5, false, paint..color = colors[2]);
    canvas.drawArc(
        rect, math.pi * 1.5, math.pi * 0.6, false, paint..color = colors[3]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}