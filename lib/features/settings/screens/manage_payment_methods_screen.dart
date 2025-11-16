import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/payment_method_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/core/services/storage_service.dart';
import 'package:proveedor_servicly_app/core/services/payment_service.dart';

// --- IMPORTACIONES NECESARIAS ---
import 'package:proveedor_servicly_app/core/constants/payment_constants.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';


/// Pantalla reutilizable para gestionar (CRUD) los métodos de pago P2P
/// (CBU, Alias, Wallets, Cripto, Efectivo, etc.)
class ManagePaymentMethodsScreen extends StatefulWidget {
  final UserModel user;

  const ManagePaymentMethodsScreen({super.key, required this.user});

  @override
  State<ManagePaymentMethodsScreen> createState() => _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState extends State<ManagePaymentMethodsScreen> {
  late final PaymentService _paymentService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentService = context.read<PaymentService>();
  }

  // --- LÓGICA DE GESTIÓN DE MÉTODOS DE PAGO (SIN CAMBIOS) ---

  Future<void> _setAsPrimary(String methodId) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final bool isMounted = mounted;

    try {
      await _paymentService.setPrimaryMethod(widget.user.uid, methodId);
      if (!isMounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Método de pago actualizado.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!isMounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMethod(String methodId) async {
    final bool? didConfirm = await _showConfirmDialog(
      'Eliminar Método',
      '¿Estás seguro de que quieres eliminar este método de pago? Esta acción no se puede deshacer.',
    );
    if (didConfirm != true) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final bool isMounted = mounted;

    try {
      await _paymentService.deletePaymentMethod(widget.user.uid, methodId);
      if (!isMounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Método eliminado.'),
        backgroundColor: Colors.redAccent,
      ));
    } catch (e) {
      if (!isMounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Error al eliminar: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddEditDialog({PaymentMethodModel? methodToEdit}) async {
    final result = await showDialog<PaymentMethodModel>(
      context: context,
      builder: (ctx) => _AddEditMethodDialog(
        method: methodToEdit,
        user: widget.user,
      ),
    );

    // Guardar contexto antes del Await
    final messenger = ScaffoldMessenger.of(context);
    final bool isMounted = mounted;

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        if (methodToEdit != null) {
          // Actualizar (asegurándonos de mantener el ID y 'isPrimary')
          final updatedMethod = result.copyWith(
            id: methodToEdit.id,
            isPrimary: methodToEdit.isPrimary,
          );
          await _paymentService.updatePaymentMethod(widget.user.uid, updatedMethod);
        } else {
          // Añadir
          await _paymentService.addPaymentMethod(widget.user.uid, result);
        }

        if (!isMounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text(methodToEdit != null ? 'Método actualizado' : 'Método añadido'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        if (!isMounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.redAccent,
        ));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- Widgets Auxiliares de UI (SIN CAMBIOS) ---

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Confirmar', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    // --- ¡CONDICIÓN DE VERIFICACIÓN! ---
    if (!widget.user.isProfileComplete) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Métodos de Pago'),
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, color: Colors.white24, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Función bloqueada',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Debes completar tu perfil de marca en "Editar Perfil" antes de poder añadir métodos de pago.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Ir a Editar Perfil'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => BrandSettingsScreen(user: widget.user),
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- VISTA PRINCIPAL (SI ESTÁ VERIFICADO) ---
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          StreamBuilder<List<PaymentMethodModel>>(
            stream: _paymentService.getPaymentMethodsStream(widget.user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
              }
              final methods = snapshot.data ?? [];

              if (methods.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_outlined, size: 80, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No has añadido métodos de pago.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: methods.length,
                itemBuilder: (context, index) {
                  final method = methods[index];
                  return _PaymentMethodCard(
                    method: method,
                    onDelete: () => _deleteMethod(method.id),
                    onEdit: () => _openAddEditDialog(methodToEdit: method),
                    onSetPrimary: () => _setAsPrimary(method.id),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: CircularProgressIndicator(color: accentColor)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

// --- WIDGET PARA LA TARJETA DE CADA MÉTODO ---
class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  const _PaymentMethodCard({
    required this.method,
    required this.onEdit,
    required this.onDelete,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    IconData icon;
    // --- Lógica de Icono Actualizada ---
    switch (method.type) {
      case PaymentMethodType.bank:
        icon = Icons.account_balance_outlined;
        break;
      case PaymentMethodType.wallet:
        icon = Icons.account_balance_wallet_outlined;
        break;
      case PaymentMethodType.crypto: // ¡NUEVO TIPO!
        icon = Icons.currency_bitcoin_outlined; // Icono para cripto
        break;
      case PaymentMethodType.other:
      default:
        icon = Icons.credit_card_outlined;
    }

    // --- Lógica de Datos a Mostrar Actualizada ---
    String displayData = '';
    if (method.cryptoAddress != null && method.cryptoAddress!.isNotEmpty) {
      displayData = "Dir. Cripto: ${method.cryptoAddress!}";
    } else if (method.alias != null && method.alias!.isNotEmpty) {
      displayData = "Alias/ID: ${method.alias!}";
    } else if (method.cbu != null && method.cbu!.isNotEmpty) {
      displayData = "CBU/CVU: ${method.cbu!}";
    } else if (method.otherDetails != null && method.otherDetails!.isNotEmpty) {
      displayData = method.otherDetails!;
    }

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: method.isPrimary
          ? const BorderSide(color: accentColor, width: 2)
          : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.white70, size: 40),
            title: Text(method.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(displayData, style: const TextStyle(color: Colors.white70)),
            trailing: method.isPrimary
                ? const Icon(Icons.check_circle, color: accentColor)
                : null,
          ),
          Container(
            height: 1,
            color: Colors.black.withAlpha(51),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: onEdit,
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: onDelete,
              ),
              if (!method.isPrimary)
                TextButton.icon(
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Principal'),
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                  onPressed: onSetPrimary,
                ),
            ],
          )
        ],
      ),
    );
  }
}

// --- WIDGET PARA EL DIÁLOGO DE AÑADIR/EDITAR (LÓGICA ACTUALIZADA) ---
class _AddEditMethodDialog extends StatefulWidget {
  final PaymentMethodModel? method;
  final UserModel user;

  const _AddEditMethodDialog({
    this.method,
    required this.user
  });

  @override
  State<_AddEditMethodDialog> createState() => _AddEditMethodDialogState();
}

class _AddEditMethodDialogState extends State<_AddEditMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late PaymentMethodType _type;

  // --- MODIFICACIONES EN VARIABLES DE ESTADO ---
  String? _selectedName; // Ahora puede ser Banco, Wallet o Cripto
  late List<String> _dropdownOptions; // Opciones dinámicas para el dropdown
  // --- FIN MODIFICACIONES ---

  late TextEditingController _aliasController;
  late TextEditingController _cbuController;
  late TextEditingController _cryptoAddressController; // ¡NUEVO!
  late TextEditingController _otherDetailsController; // Renombrado de _otherController

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    _type = m?.type ?? PaymentMethodType.bank;

    // Inicialización de controladores con datos existentes
    _aliasController = TextEditingController(text: m?.alias);
    _cbuController = TextEditingController(text: m?.cbu);
    _cryptoAddressController = TextEditingController(text: m?.cryptoAddress); // ¡NUEVO!
    _otherDetailsController = TextEditingController(text: m?.otherDetails); // Renombrado

    // Cargar opciones iniciales
    _dropdownOptions = [];
    _selectedName = m?.name;

    // Actualizar las opciones iniciales al cargar la pantalla
    _updateDropdownOptions(initialLoad: true);
  }

  /// Carga la lista de opciones para el DropdownButtonFormField de Nombre
  void _updateDropdownOptions({bool initialLoad = false}) {
    final country = widget.user.personalization['country'] as String? ?? 'Genérico';
    List<String> newOptions = [];

    switch (_type) {
      case PaymentMethodType.bank:
        // Cargar lista de bancos específica del país, con fallback a Genérico
        newOptions = List<String>.from(
          PaymentConstants.kBankLists[country] ?? PaymentConstants.kBankLists['Genérico']!
        );
        break;
      case PaymentMethodType.wallet:
        // Cargar lista de wallets específica del país, con fallback a Genérico
        newOptions = List<String>.from(
          PaymentConstants.kWalletLists[country] ?? PaymentConstants.kWalletLists['Genérico']!
        );
        break;
      case PaymentMethodType.crypto:
        // Cargar lista de criptomonedas (no depende del país)
        newOptions = List<String>.from(PaymentConstants.kCryptoLists);
        break;
      case PaymentMethodType.other:
        // Para 'other' (Efectivo), no hay dropdown, por lo que la lista está vacía.
        break;
    }

    // Si es una carga inicial y el nombre guardado no está en la nueva lista, lo insertamos
    // para que el dropdown no falle al iniciar la edición.
    if (initialLoad &&
        _selectedName != null &&
        _selectedName!.isNotEmpty &&
        newOptions.isNotEmpty &&
        !newOptions.contains(_selectedName!)) {
      newOptions.insert(0, _selectedName!);
    }

    setState(() {
      _dropdownOptions = newOptions;

      // Si cambiamos de tipo (y no es carga inicial), reiniciamos la selección del nombre
      if (!initialLoad && _type != PaymentMethodType.other) {
        _selectedName = null;
      }

      // Limpiar los campos específicos que ya no son relevantes
      if (_type != PaymentMethodType.bank) {
        _cbuController.clear();
      }
      if (_type != PaymentMethodType.bank && _type != PaymentMethodType.wallet) {
        _aliasController.clear();
      }
      if (_type != PaymentMethodType.crypto) {
        _cryptoAddressController.clear();
      }
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _cbuController.dispose();
    _cryptoAddressController.dispose(); // ¡NUEVO!
    _otherDetailsController.dispose(); // Renombrado
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    // Validación extra: si no es 'other', debe haber un nombre seleccionado.
    if (_type != PaymentMethodType.other && (_selectedName == null || _selectedName!.isEmpty)) {
      // Normalmente el validador del campo se encarga, pero aseguramos.
      return;
    }

    final navigator = Navigator.of(context);

    // Si es 'other', el "nombre" del método es simplemente "Efectivo"
    final name = _type == PaymentMethodType.other ? 'Efectivo' : _selectedName!;

    // Creamos el nuevo modelo
    final newMethod = PaymentMethodModel(
      id: widget.method?.id ?? '',
      name: name,
      type: _type,
      // Los campos se guardan si fueron llenados, si no, se guarda null.
      alias: _aliasController.text.trim().isNotEmpty ? _aliasController.text.trim() : null,
      cbu: _cbuController.text.trim().isNotEmpty ? _cbuController.text.trim() : null,
      cryptoAddress: _cryptoAddressController.text.trim().isNotEmpty ? _cryptoAddressController.text.trim() : null, // ¡NUEVO!
      otherDetails: _otherDetailsController.text.trim().isNotEmpty ? _otherDetailsController.text.trim() : null, // Renombrado
      isPrimary: widget.method?.isPrimary ?? false,
    );

    navigator.pop(newMethod);
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const inputFillColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: inputFillColor,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );

    // Lógica para el label/hintText de "Otros Detalles"
    String otherDetailsHint;
    switch (_type) {
      case PaymentMethodType.bank:
        otherDetailsHint = 'Titular de la cuenta, CUIT/ID Fiscal, etc.';
        break;
      case PaymentMethodType.wallet:
        otherDetailsHint = 'ID de la cuenta o nombre del titular.';
        break;
      case PaymentMethodType.crypto:
        otherDetailsHint = 'Red (ej: ERC20, BEP20) o notas importantes.';
        break;
      case PaymentMethodType.other:
        otherDetailsHint = 'Descripción del método (ej: Efectivo en persona).';
        break;
    }

    return AlertDialog(
      backgroundColor: surfaceColor,
      title: Text(widget.method == null ? 'Añadir Método' : 'Editar Método', style: const TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Dropdown de Tipo de Método (PaymentMethodType)
              DropdownButtonFormField<PaymentMethodType>(
                value: _type,
                decoration: inputDecoration.copyWith(labelText: 'Tipo de Método'),
                dropdownColor: surfaceColor,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: PaymentMethodType.bank, child: Text('Banco (CBU/Alias)')),
                  DropdownMenuItem(value: PaymentMethodType.wallet, child: Text('Wallet (ej: Mercado Pago)')),
                  DropdownMenuItem(value: PaymentMethodType.crypto, child: Text('Criptomonedas')), // ¡NUEVO TIPO!
                  DropdownMenuItem(value: PaymentMethodType.other, child: Text('Otro (ej: Efectivo)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                    _updateDropdownOptions(); // Cargar las nuevas opciones
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Dropdown Condicional para Nombre (Banco/Wallet/Cripto)
              if (_type != PaymentMethodType.other) ...[
                DropdownButtonFormField<String>(
                  value: _selectedName,
                  isExpanded: true,
                  decoration: inputDecoration.copyWith(
                    labelText: _type == PaymentMethodType.crypto
                        ? 'Selecciona Criptomoneda'
                        : 'Nombre (Banco o Wallet)',
                  ),
                  dropdownColor: surfaceColor,
                  style: const TextStyle(color: Colors.white),
                  items: _dropdownOptions.map((String name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedName = value;
                    });
                  },
                  validator: (value) => (value == null || value.isEmpty) ? 'Selecciona una opción' : null,
                ),
                const SizedBox(height: 16),
              ],

              // 3. Campos Específicos para Bancos
              if (_type == PaymentMethodType.bank) ...[
                TextFormField(
                  controller: _cbuController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(
                    labelText: 'CBU / CVU (Opcional)',
                    hintText: 'Clave Bancaria Uniforme o Clave Virtual Uniforme',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _aliasController, // Se reutiliza para Alias
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(labelText: 'Alias (Opcional)'),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Campos Específicos para Wallets
              if (_type == PaymentMethodType.wallet) ...[
                TextFormField(
                  controller: _aliasController, // Se reutiliza para Email/Teléfono
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(
                    labelText: 'Identificador (Email / Teléfono / Alias)',
                    hintText: 'El dato que necesita el cliente para enviarte el pago',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Campos Específicos para Criptomonedas
              if (_type == PaymentMethodType.crypto) ...[
                TextFormField(
                  controller: _cryptoAddressController, // ¡NUEVO CAMPO!
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(
                    labelText: 'Dirección de la Criptomoneda',
                    hintText: 'Ejemplo: 0xAbcdEF12345...',
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Ingresa la dirección de la criptomoneda' : null,
                ),
                const SizedBox(height: 16),
              ],


              // 6. Campo de Otros Detalles (Siempre visible, con hint dinámico)
              TextFormField(
                controller: _otherDetailsController, // Renombrado
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration.copyWith(
                  labelText: 'Otros Detalles',
                  hintText: otherDetailsHint,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
          onPressed: _onSave,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}