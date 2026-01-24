import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
import 'universal_dashboard_card.dart';

class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextEventAsync = ref.watch(nextAppointmentProvider);

    return nextEventAsync.when(
      loading: () => const UniversalDashboardCard(title: "AGENDA", icon: Icons.calendar_today, primaryColor: Colors.grey, mainValue: "", isLoading: true),
      error: (_, __) => const UniversalDashboardCard(title: "ERROR", icon: Icons.error, primaryColor: Colors.red, mainValue: "Error"),
      data: (event) {
        final bool hasAppt = event != null;
        final bool isPending = hasAppt && event.eventStatus == EventStatus.pendingApproval;
        final Color color = isPending ? Colors.orangeAccent : const Color(0xFF7B61FF);

        if (!hasAppt) {
          return UniversalDashboardCard(
            title: "AGENDA",
            icon: Icons.calendar_today_rounded,
            primaryColor: const Color(0xFF7B61FF),
            mainValue: "Libre",
            subContent: const Text("Sin citas pendientes"),
          );
        }

        return UniversalDashboardCard(
          title: isPending ? "PENDIENTE" : "PRÓXIMA",
          icon: isPending ? Icons.notification_important : Icons.access_time_filled,
          primaryColor: color,
          mainValue: DateFormat('HH:mm').format(event.startTime),
          subContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              Opacity(
                opacity: 0.7,
                child: Text(DateFormat('d MMM').format(event.startTime), style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }
}