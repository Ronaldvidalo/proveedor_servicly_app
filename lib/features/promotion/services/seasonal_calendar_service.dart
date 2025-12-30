import 'package:flutter/foundation.dart';

class SeasonalCalendarService {
  
  // -----------------------------------------------------------------------
  // 📅 BASE DE DATOS DE EFEMÉRIDES COMERCIALES (LATAM + ES)
  // Fechas ajustadas para el ciclo comercial 2025.
  // -----------------------------------------------------------------------
  static final Map<String, List<Map<String, dynamic>>> _calendarsByCountry = {
    
    // 🇦🇷 ARGENTINA
    'AR': [
      {'name': 'Reyes Magos', 'month': 1, 'day': 6, 'icon': '👑'},
      {'name': 'San Valentín', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'}, // 3er domingo junio
      {'name': 'Día del Amigo', 'month': 7, 'day': 20, 'icon': '🍻'}, // Muy fuerte en AR
      {'name': 'Día del Niño', 'month': 8, 'day': 17, 'icon': '🧸'}, // 3er domingo agosto
      {'name': 'Día de la Madre', 'month': 10, 'day': 19, 'icon': '👑'}, // 3er domingo octubre
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇧🇴 BOLIVIA
    'BO': [
      {'name': 'Día del Padre', 'month': 3, 'day': 19, 'icon': '👔'}, // Fijo (San José)
      {'name': 'Día del Niño', 'month': 4, 'day': 12, 'icon': '🧸'}, // Fijo
      {'name': 'Día de la Madre', 'month': 5, 'day': 27, 'icon': '👑'}, // Fijo (Heroínas Coronilla)
      {'name': 'Día de la Amistad', 'month': 7, 'day': 23, 'icon': '🤝'},
      {'name': 'Día del Estudiante', 'month': 9, 'day': 21, 'icon': '🎓'},
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇧🇷 BRASIL (El distinto de la región)
    'BR': [
      {'name': 'Dia das Mães', 'month': 5, 'day': 11, 'icon': '👑'}, // 2do domingo mayo
      {'name': 'Dia dos Namorados', 'month': 6, 'day': 12, 'icon': '💘'}, // San Valentín es en Junio
      {'name': 'Dia dos Pais', 'month': 8, 'day': 10, 'icon': '👔'}, // 2do domingo agosto
      {'name': 'Dia das Crianças', 'month': 10, 'day': 12, 'icon': '🧸'},
      {'name': 'Black Friday', 'month': 11, 'day': 28, 'icon': '🛍️'},
      {'name': 'Natal', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇨🇱 CHILE
    'CL': [
      {'name': 'San Valentín', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'},
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'},
      {'name': 'Día del Niño', 'month': 8, 'day': 10, 'icon': '🧸'},
      {'name': 'Fiestas Patrias', 'month': 9, 'day': 18, 'icon': '🇨🇱'}, // Super comercial (18 y 19)
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇨🇴 COLOMBIA (Amor y Amistad es clave)
    'CO': [
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'}, // 2do domingo mayo
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'}, // 3er domingo junio
      {'name': 'Amor y Amistad', 'month': 9, 'day': 20, 'icon': '💖'}, // 3er sábado sept (El San Valentín real)
      {'name': 'Halloween', 'month': 10, 'day': 31, 'icon': '🎃'},
      {'name': 'Día de las Velitas', 'month': 12, 'day': 7, 'icon': '🕯️'},
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇪🇨 ECUADOR
    'EC': [
      {'name': 'San Valentín', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'},
      {'name': 'Día del Niño', 'month': 6, 'day': 1, 'icon': '🧸'}, // Fijo
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'},
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇵🇾 PARAGUAY
    'PY': [
      {'name': 'Día de los Enamorados', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 15, 'icon': '👑'}, // Fijo (Independencia)
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'},
      {'name': 'Día de la Amistad', 'month': 7, 'day': 30, 'icon': '🤝'}, // Muy importante
      {'name': 'Día del Niño', 'month': 8, 'day': 16, 'icon': '🧸'}, // Fijo (Acosta Ñu)
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇵🇪 PERÚ
    'PE': [
      {'name': 'San Valentín', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'},
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'},
      {'name': 'Fiestas Patrias', 'month': 7, 'day': 28, 'icon': '🇵🇪'}, // 28 y 29 Julio
      {'name': 'Día del Niño', 'month': 8, 'day': 17, 'icon': '🧸'},
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇺🇾 URUGUAY
    'UY': [
      {'name': 'Día de los Enamorados', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'},
      {'name': 'Día del Padre', 'month': 7, 'day': 13, 'icon': '👔'}, // 2do domingo Julio (Diferente al resto)
      {'name': 'Día del Niño', 'month': 8, 'day': 10, 'icon': '🧸'}, // 2do domingo agosto
      {'name': 'Noche de la Nostalgia', 'month': 8, 'day': 24, 'icon': '💃'}, // Evento cultural/comercial masivo
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇻🇪 VENEZUELA
    'VE': [
      {'name': 'Día del Amor y Amistad', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'}, // 2do domingo mayo
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'}, // 3er domingo junio
      {'name': 'Día del Niño', 'month': 7, 'day': 20, 'icon': '🧸'}, // 3er domingo julio
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🇪🇸 ESPAÑA
    'ES': [
      {'name': 'Reyes Magos', 'month': 1, 'day': 6, 'icon': '👑'}, // Clave para regalos
      {'name': 'Día del Padre', 'month': 3, 'day': 19, 'icon': '👔'}, // Fijo (San José)
      {'name': 'Día de la Madre', 'month': 5, 'day': 4, 'icon': '👑'}, // 1er domingo mayo
      {'name': 'Rebajas de Verano', 'month': 7, 'day': 1, 'icon': '🏷️'},
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ],

    // 🌍 DEFAULT / INTERNACIONAL
    'default': [
      {'name': 'San Valentín', 'month': 2, 'day': 14, 'icon': '❤️'},
      {'name': 'Día de la Madre', 'month': 5, 'day': 11, 'icon': '👑'},
      {'name': 'Día del Padre', 'month': 6, 'day': 15, 'icon': '👔'},
      {'name': 'Black Friday', 'month': 11, 'day': 28, 'icon': '🛍️'},
      {'name': 'Navidad', 'month': 12, 'day': 25, 'icon': '🎄'},
    ]
  };

  /// Devuelve el próximo evento comercial importante para el país especificado.
  /// Recibe [countryCode] (ej: "AR", "MX"). Si es nulo o no existe, usa 'default'.
  Map<String, dynamic>? getUpcomingEvent(String? countryCode) {
    final now = DateTime.now();
    
    // 1. Normalización del código de país
    final String targetCode = (countryCode?.toUpperCase() ?? 'default');
    
    // 2. Selección del calendario (Si no existe el país, usa default)
    final List<Map<String, dynamic>> selectedCalendar = 
        _calendarsByCountry.containsKey(targetCode) 
            ? _calendarsByCountry[targetCode]! 
            : _calendarsByCountry['default']!;

    debugPrint("📅 SeasonalService: Analizando calendario para $targetCode");

    for (var event in selectedCalendar) {
      // Creamos la fecha del evento para el año actual
      DateTime eventDate = DateTime(now.year, event['month'] as int, event['day'] as int);
      
      // Si la fecha ya pasó este año, miramos la del año que viene para no perder la referencia,
      // aunque para "upcoming" nos interesa lo que viene pronto.
      if (eventDate.isBefore(now.subtract(const Duration(days: 1)))) {
         eventDate = DateTime(now.year + 1, event['month'] as int, event['day'] as int);
      }

      final diff = eventDate.difference(now).inDays;

      // REGLA DE NEGOCIO: Anticipación de 25 días (aprox 3-4 semanas)
      // Aumenté un poco el rango para dar tiempo a preparar la campaña.
      if (diff >= 0 && diff <= 25) {
        return {
          'name': event['name'],
          'days_left': diff,
          'date': eventDate,
          'icon': event['icon'],
          'country': targetCode 
        };
      }
    }
    return null; // No hay eventos cercanos en la ventana de tiempo
  }
}