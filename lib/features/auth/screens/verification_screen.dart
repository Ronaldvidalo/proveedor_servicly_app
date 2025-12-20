import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with WidgetsBindingObserver {
  // --- VARIABLES ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StorageService _storageService;
  
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Phone Auth
  String? _verificationId;
  bool _codeSent = false;
  String _userCountryCode = 'AR'; 
  String _dialingPrefix = '+54';

  Timer? _emailTimer;
  int _emailResendCountdown = 0;

  final ImagePicker _picker = ImagePicker();
  File? _idImage; // Ahora es opcional
  bool _isLoading = false;

  final Map<String, String> _countryPrefixes = {
    'AR': '+54', 'BO': '+591', 'BR': '+55', 'CL': '+56',
    'CO': '+57', 'EC': '+593', 'PY': '+595', 'PE': '+51',
    'UY': '+598', 'VE': '+58', 'ES': '+34',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _storageService = context.read<StorageService>();
    _checkInitialStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailTimer?.cancel();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkEmailVerified(silent: true);
    }
  }

  Future<void> _checkInitialStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      setState(() {
        _isEmailVerified = user.emailVerified;
      });
      
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
         final data = doc.data();
         if (data != null) {
            if (data['phoneVerified'] == true) setState(() => _isPhoneVerified = true);
            if (data['shippingAddress'] != null) _addressController.text = data['shippingAddress'];
            
            String? countryCode;
            if (data['personalization'] != null) countryCode = data['personalization']['country'];
            else if (data['country'] != null) countryCode = data['country'];

            if (countryCode != null && _countryPrefixes.containsKey(countryCode)) {
               setState(() {
                 _userCountryCode = countryCode!;
                 _dialingPrefix = _countryPrefixes[countryCode]!;
               });
            }
         }
      }
    }
  }

  // --- LÓGICA DE EMAIL Y TELÉFONO (IGUAL QUE ANTES) ---
  Future<void> _sendEmailLink() async {
    if (_emailResendCountdown > 0) return;
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace enviado. Revisa tu correo.'), backgroundColor: Colors.blueAccent));
        setState(() => _emailResendCountdown = 60);
        _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_emailResendCountdown > 0) setState(() => _emailResendCountdown--);
          else timer.cancel();
        });
      } catch (e) { _showError('Error enviando correo: $e'); }
    }
  }

  Future<void> _checkEmailVerified({bool silent = false}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        setState(() => _isEmailVerified = true);
        if (!silent) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Email verificado!'), backgroundColor: Colors.green));
      } else if (!silent) _showError('Aún no verificado.');
    }
  }

  Future<void> _verifyPhoneNumber() async {
    String number = _phoneController.text.trim();
    if (number.isEmpty) return _showError('Ingresa tu número');

    if (!number.startsWith('+')) {
      number = number.replaceAll(' ', '').replaceAll('-', '');
      if (_userCountryCode == 'AR') {
         if (number.startsWith('15')) number = number.substring(2);
         if (!number.startsWith('9')) number = '9$number';
      }
      number = '$_dialingPrefix$number';
    }

    setState(() => _isLoading = true);
    await _auth.verifyPhoneNumber(
      phoneNumber: number, 
      verificationCompleted: (c) async {
        await _auth.currentUser!.updatePhoneNumber(c);
        setState(() { _isPhoneVerified = true; _isLoading = false; });
      },
      verificationFailed: (e) {
        setState(() => _isLoading = false);
        _showError(e.code == 'invalid-phone-number' ? 'Número inválido.' : 'Error SMS: ${e.message}');
      },
      codeSent: (id, token) {
        setState(() { _verificationId = id; _codeSent = true; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SMS enviado a $number')));
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  Future<void> _confirmSmsCode() async {
    if (_smsCodeController.text.isEmpty || _verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential c = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _smsCodeController.text.trim());
      await _auth.currentUser!.updatePhoneNumber(c);
      setState(() { _isPhoneVerified = true; _codeSent = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Teléfono verificado!'), backgroundColor: Colors.green));
    } catch (e) { _showError('Código inválido'); } 
    finally { setState(() => _isLoading = false); }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
      if (image != null) setState(() => _idImage = File(image.path));
    } catch (e) { _showError('Error cámara: $e'); }
  }

  // --- ENVÍO FINAL (MODIFICADO: DNI OPCIONAL) ---
  Future<void> _submitAll() async {
    // 1. Validaciones OBLIGATORIAS
    if (!_isEmailVerified) return _showError('Falta verificar Email');
    if (!_isPhoneVerified) return _showError('Falta verificar Teléfono');
    // La dirección aquí es solo una confirmación, el checkout pedirá la específica
    
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? downloadUrl;
      
      // 2. Subida de DNI (Solo si el usuario tomó la foto)
      if (_idImage != null) {
        final String path = 'verifications/${user.uid}/id_card_${DateTime.now().millisecondsSinceEpoch}.jpg';
        downloadUrl = await _storageService.uploadFileWithProgress(_idImage!, path, (_) {});
      }

      // 3. Guardar en Firestore
      // Ponemos 'isVerified: true' porque cumplió con Email+Tlf que es lo mínimo para comprar.
      // Podemos usar otro flag 'identityVerified' para diferenciar si subió DNI.
      await _db.collection('users').doc(user.uid).update({
        'isVerified': true,             
        'verificationStatus': _idImage != null ? 'pending_review' : 'basic_verified', 
        'emailVerified': true,
        'phoneVerified': true,
        'phoneNumber': user.phoneNumber ?? _phoneController.text,
        'shippingAddress': _addressController.text.trim(), 
        if (downloadUrl != null) 'idCardUrl': downloadUrl, // Solo si subió
        'verificationDate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('¡Cuenta Verificada!', style: TextStyle(color: Colors.white)),
            content: Text(
              _idImage != null 
                ? 'Has completado la verificación de identidad completa.' 
                : 'Has completado la verificación básica. Ya puedes realizar compras.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Volver al checkout
                },
                child: const Text('CONTINUAR', style: TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Error guardando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: const Text("Centro de Verificación"), backgroundColor: bgColor, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Seguridad y Confianza.", style: TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),

            _buildStepCard(title: "1. Validar Email (Obligatorio)", isDone: _isEmailVerified, accentColor: accentColor, 
              child: _isEmailVerified ? const Text("✅ Listo", style: TextStyle(color: Colors.greenAccent)) 
              : Row(children: [
                  Expanded(child: OutlinedButton(onPressed: _emailResendCountdown > 0 ? null : _sendEmailLink, child: Text(_emailResendCountdown > 0 ? "${_emailResendCountdown}s" : "Enviar Enlace"))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: () => _checkEmailVerified(), style: FilledButton.styleFrom(backgroundColor: accentColor), child: const Text("Ya confirmé"))),
                ])),

            _buildStepCard(title: "2. Validar Teléfono (Obligatorio)", isDone: _isPhoneVerified, accentColor: accentColor,
              child: _isPhoneVerified ? Text("✅ ${_auth.currentUser?.phoneNumber}", style: const TextStyle(color: Colors.greenAccent))
              : _codeSent 
                ? Row(children: [
                    Expanded(child: TextField(controller: _smsCodeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Código SMS", border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    FilledButton(onPressed: _isLoading ? null : _confirmSmsCode, style: FilledButton.styleFrom(backgroundColor: accentColor), child: const Text("Confirmar"))
                  ])
                : Row(children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black26, border: Border.all(color: Colors.white24)), child: Text(_dialingPrefix, style: const TextStyle(color: Colors.white))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Número", border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    IconButton(onPressed: _isLoading ? null : _verifyPhoneNumber, icon: const Icon(Icons.send, color: Colors.blueAccent))
                  ])),

            _buildStepCard(title: "3. Dirección Principal", isDone: _addressController.text.isNotEmpty, accentColor: accentColor,
              child: TextField(controller: _addressController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Calle, Altura, Ciudad", border: OutlineInputBorder()), onChanged: (_) => setState((){}))),

            // --- PASO 4: FOTO OPCIONAL ---
            _buildStepCard(
              title: "4. Foto DNI (Opcional)", // Marcado como opcional
              isDone: _idImage != null,
              accentColor: accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sube tu DNI para obtener la insignia de 'Verificado' y mayor confianza.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 100, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.black26, border: Border.all(color: _idImage != null ? Colors.green : Colors.white24), borderRadius: BorderRadius.circular(8)),
                      child: _idImage != null ? Image.file(_idImage!, fit: BoxFit.cover) : Icon(Icons.camera_alt, color: accentColor, size: 30),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                // Habilitado si Email y Telefono están OK. Foto y dirección no bloquean (pero dirección se valida arriba).
                onPressed: (_isEmailVerified && _isPhoneVerified && !_isLoading) ? _submitAll : null,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black, disabledBackgroundColor: Colors.grey.withOpacity(0.2)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("FINALIZAR VERIFICACIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({required String title, required bool isDone, required Color accentColor, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDone ? Colors.greenAccent.withOpacity(0.5) : Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), if (isDone) const Icon(Icons.check_circle, color: Colors.greenAccent)]),
        const Divider(color: Colors.white10),
        const SizedBox(height: 8),
        child
      ]),
    );
  }
}