import 'package:flutter/material.dart';

// Esta lista alimenta el Onboarding y los Filtros de búsqueda.
// Al agregar categorías aquí, Servi automáticamente podrá filtrarlas en el Home.

const List<Map<String, dynamic>> kProfessions = [
  // --- COMERCIOS Y TIENDAS (Marketplace Retail) ---
  {'label': 'Indumentaria y Moda', 'icon': Icons.checkroom},
  {'label': 'Zapatería', 'icon': Icons.hiking}, // O shopping_bag
  {'label': 'Electrónica y Celulares', 'icon': Icons.devices},
  {'label': 'Informática y Gaming', 'icon': Icons.computer},
  {'label': 'Muebles y Decoración', 'icon': Icons.chair},
  {'label': 'Librería y Papelería', 'icon': Icons.menu_book},
  {'label': 'Juguetería', 'icon': Icons.toys},
  {'label': 'Ferretería (Tienda)', 'icon': Icons.build_circle},
  {'label': 'Gastronomía', 'icon': Icons.restaurant},
  {'label': 'Almacén / Kiosco', 'icon': Icons.storefront},

  // --- ESTÉTICA Y CUIDADO PERSONAL ---
  {'label': 'Peluquería y Barbería', 'icon': Icons.content_cut},
  {'label': 'Estética y Belleza', 'icon': Icons.face},
  {'label': 'Manicure / Pedicure', 'icon': Icons.back_hand},
  {'label': 'Spa y Masajes', 'icon': Icons.spa},
  {'label': 'Tatuajes', 'icon': Icons.brush}, // O color_lens

  // --- SALUD ---
  {'label': 'Médico / Salud', 'icon': Icons.medical_services},
  {'label': 'Odontología', 'icon': Icons.health_and_safety},
  {'label': 'Psicología', 'icon': Icons.psychology},
  {'label': 'Farmacia', 'icon': Icons.local_pharmacy},
  {'label': 'Kinesiología', 'icon': Icons.accessibility_new},

  // --- MASCOTAS ---
  {'label': 'Veterinaria', 'icon': Icons.local_hospital},
  {'label': 'Pet Shop y Alimentos', 'icon': Icons.pets},
  {'label': 'Paseador / Cuidador', 'icon': Icons.directions_walk},

  // --- SERVICIOS TÉCNICOS Y OFICIOS (Hogar) ---
  {'label': 'Plomería', 'icon': Icons.plumbing},
  {'label': 'Gasista', 'icon': Icons.fire_extinguisher},
  {'label': 'Electricista', 'icon': Icons.electrical_services},
  {'label': 'Refrigeración', 'icon': Icons.ac_unit},
  {'label': 'Cerrajero', 'icon': Icons.vpn_key},
  {'label': 'Albañil', 'icon': Icons.construction},
  {'label': 'Pintor', 'icon': Icons.format_paint},
  {'label': 'Carpintería', 'icon': Icons.handyman},
  {'label': 'Herrería', 'icon': Icons.fence},
  {'label': 'Jardinería', 'icon': Icons.grass},
  {'label': 'Limpieza', 'icon': Icons.cleaning_services},
  {'label': 'Control de plagas', 'icon': Icons.bug_report},
  {'label': 'Soldador', 'icon': Icons.precision_manufacturing},
  {'label': 'Seguridad', 'icon': Icons.security},

  // --- AUTOMOTOR ---
  {'label': 'Mecánico', 'icon': Icons.car_repair},
  {'label': 'Lavadero de Autos', 'icon': Icons.local_car_wash},
  {'label': 'Gomería', 'icon': Icons.tire_repair},

  // --- PROFESIONALES INDEPENDIENTES ---
  {'label': 'Abogado', 'icon': Icons.gavel},
  {'label': 'Contador', 'icon': Icons.calculate},
  {'label': 'Arquitectura', 'icon': Icons.architecture},
  {'label': 'Diseño y Marketing', 'icon': Icons.palette},
  {'label': 'Seguros', 'icon': Icons.shield},

  // --- VARIOS ---
  {'label': 'Transporte y Flete', 'icon': Icons.local_shipping},
  {'label': 'Servicio Técnico (TV/Audio)', 'icon': Icons.settings_input_component},
  {'label': 'Cuidado de Personas', 'icon': Icons.elderly},
  {'label': 'Otros', 'icon': Icons.more_horiz},
];