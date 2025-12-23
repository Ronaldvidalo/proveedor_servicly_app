import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Controladores
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Estados de carga y verificación
  bool _isLoading = false;
  bool _isCheckingInitialStatus = true;
  
  // Estados de los pasos
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isAddressSaved = false;

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _checkCurrentStatus();
  }

  /// 1. OPTIMIZACIÓN: Verificar estado inicial para evitar pedir datos repetidos.
  Future<void> _checkCurrentStatus() async {
    if (_currentUser == null) return;

    try {
      // Recargar usuario de Auth para ver si verificó email recientemente
      await _currentUser!.reload();
      final userAuth = FirebaseAuth.instance.currentUser; // Instancia fresca

      // Consultar Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Verificar si ya tiene el estatus básico
        if (data['verificationStatus'] == 'basic_verified') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ya estás verificado. Redirigiendo...")),
            );
            Navigator.pop(context, true); // Retorna éxito inmediatamente
            return;
          }
        }

        // Cargar datos existentes si los hay
        if (data['phoneNumber'] != null) {
          _phoneController.text = data['phoneNumber'];
          setState(() => _isPhoneVerified = true);
        }
        if (data['address'] != null) {
          _addressController.text = data['address'];
          setState(() => _isAddressSaved = true);
        }
      }

      setState(() {
        _isEmailVerified = userAuth?.emailVerified ?? false;
        _isCheckingInitialStatus = false;
      });

    } catch (e) {
      debugPrint("Error verificando estado: $e");
      setState(() => _isCheckingInitialStatus = false);
    }
  }

  /// 2. EMAIL: Lógica real de envío y comprobación
  Future<void> _sendEmailVerification() async {
    setState(() => _isLoading = true);
    try {
      await _currentUser!.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Correo enviado. Revisa tu bandeja de entrada."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar correo: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isLoading = true);
    await _currentUser!.reload(); // Forzar actualización de Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _isEmailVerified = user?.emailVerified ?? false;
      _isLoading = false;
    });

    if (_isEmailVerified) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Email verificado correctamente!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aún no detectamos la verificación. Intenta de nuevo.")),
      );
    }
  }

  /// 3. TELÉFONO: UX mejorada con loading
  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un número válido")),
      );
      return;
    }

    // UX: Mostrar carga para que no parezca que la app se colgó
    setState(() => _isLoading = true);

    try {
      // Simulamos espera de red (o aquí iría tu lógica de SMS real)
      await Future.delayed(const Duration(seconds: 2)); 

      // Guardado parcial en Firestore
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'phoneNumber': _phoneController.text.trim(),
      });

      setState(() {
        _isPhoneVerified = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teléfono guardado.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar teléfono: $e")),
        );
      }
    } finally {
      // UX: Quitar carga
      setState(() => _isLoading = false);
    }
  }

  /// 4. GEOLOCALIZACIÓN: Obtener dirección actual
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados';
        }
      }

      // Obtener coordenadas
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convertir a dirección (Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Formato: Calle 123, Ciudad, País
        String address = "${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
        
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de ubicación: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'address': _addressController.text.trim(),
      });
      setState(() => _isAddressSaved = true);
    } catch (e) {
      debugPrint("Error guardando dirección: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 5. FINALIZAR: Lógica de Base de Datos
  Future<void> _completeBasicVerification() async {
    if (!_isEmailVerified || !_isPhoneVerified || !_isAddressSaved) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor completa todos los pasos anteriores.")),
        );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // AQUÍ LA LÓGICA IMPORTANTE DE LA DB
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'verificationStatus': 'basic_verified', 
        // NO tocamos isVerified, eso requiere DNI
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Verificación básica completada!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Regresar con éxito
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error finalizando: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingInitialStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Verificación Requerida")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Para realizar compras, necesitamos validar tu identidad básica.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // --- PASO 1: EMAIL ---
                _buildSectionCard(
                  title: "1. Correo Electrónico",
                  isCompleted: _isEmailVerified,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${_currentUser?.email ?? 'No disponible'}"),
                      const SizedBox(height: 10),
                      if (!_isEmailVerified)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _sendEmailVerification,
                                child: const Text("Enviar Link"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _checkEmailVerified,
                                child: const Text("Ya validé"),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // --- PASO 2: TELÉFONO ---
                _buildSectionCard(
                  title: "2. Teléfono Celular",
                  isCompleted: _isPhoneVerified,
                  child: Column(
                    children: [
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: "+54 9 11...",
                          labelText: "Número de contacto",
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isPhoneVerified, 
                      ),
                      const SizedBox(height: 10),
                      if (!_isPhoneVerified)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _verifyPhone,
                            child: const Text("Validar Teléfono"),
                          ),
                        ),
                    ],
                  ),
                ),

                // --- PASO 3: DIRECCIÓN ---
                _buildSectionCard(
                  title: "3. Dirección de Envío",
                  isCompleted: _isAddressSaved,
                  child: Column(
                    children: [
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "Calle, Altura, Ciudad",
                          labelText: "Domicilio",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.blue),
                            onPressed: _getCurrentLocation,
                            tooltip: "Usar mi ubicación",
                          ),
                        ),
                        onChanged: (val) {
                           // Si edita manualmente, reseteamos el estado de guardado
                           if(_isAddressSaved) setState(() => _isAddressSaved = false);
                        },
                      ),
                      const SizedBox(height: 10),
                      if (!_isAddressSaved)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveAddress,
                            child: const Text("Guardar Dirección"),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                
                // BOTÓN FINAL
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: (_isEmailVerified && _isPhoneVerified && _isAddressSaved)
                        ? _completeBasicVerification
                        : null, // Deshabilitado hasta completar todo
                    child: const Text("FINALIZAR VERIFICACIÓN"),
                  ),
                ),
              ],
            ),
          ),

          // OVERLAY DE CARGA (Para mejorar la UX "congelada")
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Procesando...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget auxiliar para las tarjetas de pasos
  Widget _buildSectionCard({required String title, required bool isCompleted, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}