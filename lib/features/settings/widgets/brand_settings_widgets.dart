import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/settings/screens/manage_payment_methods_screen.dart';

// --- UTILIDADES DE COLOR Y TEMAS ---

class PublicThemeData {
  final String id;
  final String name;
  final Color background;
  final Color surface;

  const PublicThemeData({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
  });
}

final List<PublicThemeData> publicProfileThemes = [
  const PublicThemeData(id: 'cyber_glow', name: 'Cyber Glow', background: Color(0xFF1A1A2E), surface: Color(0xFF2D2D5A)),
  const PublicThemeData(id: 'nebula_purple', name: 'Nebula Purple', background: Color(0xFF2E1A2E), surface: Color(0xFF4A2D4A)),
  const PublicThemeData(id: 'crimson_red', name: 'Crimson Red', background: Color(0xFF2E1A1A), surface: Color(0xFF4A2D2D)),
  const PublicThemeData(id: 'matrix_green', name: 'Matrix Green', background: Color(0xFF1A2E1A), surface: Color(0xFF2D4A2D)),
];

Color getOnColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black;
}

// --- WIDGETS REUTILIZABLES ---

class BrandSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const BrandSectionCard({super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class IdentityCard extends StatelessWidget {
  final XFile? imageFile;
  final String? existingLogoUrl;
  final VoidCallback onTapLogo;
  final TextEditingController nameController;
  final InputDecoration decoration;

  const IdentityCard({
    super.key,
    this.imageFile,
    this.existingLogoUrl,
    required this.onTapLogo,
    required this.nameController,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    ImageProvider? image;
    if (imageFile != null) {
      image = FileImage(File(imageFile!.path));
    } else if (existingLogoUrl != null && existingLogoUrl!.isNotEmpty) {
      image = NetworkImage(existingLogoUrl!);
    }

    return Row(
      children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
                  border: Border.all(color: colors.primary, width: 2),
                  color: image == null ? colors.surface.withValues(alpha: 0.4) : Colors.transparent,
                ),
                child: image == null ? Center(child: Icon(Icons.business_rounded, size: 40, color: colors.onSurface.withValues(alpha: 0.7))) : null,
              ),
              Positioned(
                bottom: -4, right: -4,
                child: GestureDetector(
                  onTap: onTapLogo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle, border: Border.all(color: colors.surface, width: 2)),
                    child: Icon(Icons.edit, size: 18, color: colors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: nameController,
            style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface),
            decoration: decoration.copyWith(labelText: 'Nombre de tu Negocio'),
            validator: (value) => value == null || value.trim().isEmpty ? 'Campo requerido' : null,
          ),
        ),
      ],
    );
  }
}

class ColorSelector extends StatelessWidget {
  final String title;
  final List<Color> predefinedColors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorSelector({super.key, required this.title, required this.predefinedColors, required this.selectedColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16, runSpacing: 16,
          children: predefinedColors.map((color) {
            // ✅ CORRECCIÓN: 'value' deprecated, usamos toARGB32() para comparación segura
            bool isSelected = selectedColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                  boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 10)] : [],
                ),
                child: isSelected ? Icon(Icons.check, color: getOnColor(color), size: 24) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ThemeSelector extends StatelessWidget {
  final String selectedThemeId;
  final ValueChanged<String> onThemeSelected;

  const ThemeSelector({super.key, required this.selectedThemeId, required this.onThemeSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tema de Fondo (Público)', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 250, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5),
          itemCount: publicProfileThemes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final themeData = publicProfileThemes[index];
            final bool isSelected = themeData.id == selectedThemeId;
            final Color previewPrimaryColor = Theme.of(context).colorScheme.primary;
            return InkWell(
              onTap: () => onThemeSelected(themeData.id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: themeData.background, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? previewPrimaryColor : Colors.white.withValues(alpha: 0.3), width: isSelected ? 3 : 1),
                ),
                child: Center(
                  child: Text(themeData.name, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
            );
          },
        )
      ],
    );
  }
}

class TemplateSelector extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String> onFormatSelected;

  const TemplateSelector({super.key, required this.selectedFormat, required this.onFormatSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TemplateCard(title: 'Tienda', icon: Icons.store_mall_directory_outlined, isSelected: selectedFormat == 'store', onTap: () => onFormatSelected('store'))),
        const SizedBox(width: 12),
        Expanded(child: _TemplateCard(title: 'Catálogo', icon: Icons.auto_stories_outlined, isSelected: selectedFormat == 'catalog', onTap: () => onFormatSelected('catalog'))),
        const SizedBox(width: 12),
        Expanded(child: _TemplateCard(title: 'CV Simple', icon: Icons.person_pin_outlined, isSelected: selectedFormat == 'cv', onTap: () => onFormatSelected('cv'))),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = const Color(0xFF00FF7F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? successColor.withValues(alpha: 0.12) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? successColor : colors.surface, width: isSelected ? 2.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, size: 32, color: isSelected ? successColor : colors.onSurface.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.labelLarge?.copyWith(color: isSelected ? successColor : colors.onSurface, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class PaymentMethodsCard extends StatelessWidget {
  final UserModel user;
  const PaymentMethodsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ManagePaymentMethodsScreen(user: user))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(children: [
            Icon(Icons.credit_card_outlined, color: colors.primary, size: 28),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Métodos de Pago', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("1 cuenta configurada (MercadoPago)", style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7))),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, color: colors.onSurface.withValues(alpha: 0.3), size: 16),
          ]),
        ),
      ),
    );
  }
}

class ContactInfoSection extends StatelessWidget {
  final InputDecoration decoration;
  final TextEditingController phoneController;
  final TextEditingController whatsappController;
  final TextEditingController websiteController;
  final TextEditingController instagramController;
  final TextEditingController facebookController;
  final TextEditingController tiktokController;
  final String dialCode;

  const ContactInfoSection({
    super.key,
    required this.decoration,
    required this.phoneController,
    required this.whatsappController,
    required this.websiteController,
    required this.instagramController,
    required this.facebookController,
    required this.tiktokController,
    required this.dialCode,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: 'Contacto y Redes Sociales',
      subtitle: 'Añade tus vías de contacto. El código de país ($dialCode) se añadirá automáticamente.',
      children: [
        PhoneInputWithPrefix(controller: phoneController, dialCode: dialCode, label: "Teléfono", icon: Icons.phone_outlined, decoration: decoration),
        const SizedBox(height: 16),
        PhoneInputWithPrefix(controller: whatsappController, dialCode: dialCode, label: "WhatsApp", icon: Icons.message_outlined, decoration: decoration),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        ClickableIconFormField(controller: websiteController, icon: Icons.language_outlined, label: 'Página Web', hint: 'https://tu-pagina.com', keyboardType: TextInputType.url, decoration: decoration),
        const SizedBox(height: 12),
        ClickableIconFormField(controller: instagramController, icon: Icons.camera_alt_outlined, label: 'Instagram', hint: 'tuusuario (sin @)', keyboardType: TextInputType.text, decoration: decoration),
        const SizedBox(height: 12),
        ClickableIconFormField(controller: facebookController, icon: Icons.facebook_outlined, label: 'Facebook', hint: 'tuusuario o enlace', keyboardType: TextInputType.text, decoration: decoration),
        const SizedBox(height: 12),
        ClickableIconFormField(controller: tiktokController, icon: Icons.music_note_outlined, label: 'TikTok', hint: '@tuusuario', keyboardType: TextInputType.text, decoration: decoration),
      ],
    );
  }
}

class PhoneInputWithPrefix extends StatelessWidget {
  final TextEditingController controller;
  final String dialCode;
  final String label;
  final IconData icon;
  final InputDecoration decoration;

  const PhoneInputWithPrefix({super.key, required this.controller, required this.dialCode, required this.label, required this.icon, required this.decoration});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: colors.onSurface.withValues(alpha: 0.7), size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold))]),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.onSurface.withValues(alpha: 0.2))),
          child: Text(dialCode, style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(child: TextFormField(controller: controller, keyboardType: TextInputType.phone, style: TextStyle(color: colors.onSurface), decoration: decoration.copyWith(hintText: 'Ej: 11 1234 5678', prefixIcon: null))),
      ]),
    ]);
  }
}

class ClickableIconFormField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final InputDecoration decoration;

  const ClickableIconFormField({super.key, required this.controller, required this.icon, required this.label, required this.hint, required this.keyboardType, required this.decoration});

  @override
  State<ClickableIconFormField> createState() => _ClickableIconFormFieldState();
}

class _ClickableIconFormFieldState extends State<ClickableIconFormField> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) _isExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isFilled = widget.controller.text.isNotEmpty;
    return Column(children: [
      InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Row(children: [
          Icon(widget.icon, color: isFilled ? colors.primary : colors.onSurface.withValues(alpha: 0.5), size: 24),
          const SizedBox(width: 16),
          Text(widget.label, style: TextStyle(color: isFilled ? colors.onSurface : colors.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: colors.onSurface.withValues(alpha: 0.5)),
        ]),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
        child: _isExpanded ? Padding(padding: const EdgeInsets.only(top: 12.0), child: TextFormField(controller: widget.controller, style: TextStyle(color: colors.onSurface), decoration: widget.decoration.copyWith(hintText: widget.hint, prefixIcon: null), keyboardType: widget.keyboardType, onChanged: (_) => setState(() {}))) : const SizedBox(width: double.infinity, height: 0),
      ),
    ]);
  }
}