import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_router.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_banner.dart';
import '../../constants/app_constants.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointmentProvider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appointmentsTitle),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: appointmentProvider.appointmentsState.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 3,
          itemBuilder: (_, __) => const CardSkeleton(lines: 2),
        ),
        data: (appointments) {
          if (appointments.isEmpty) {
            return EmptyState(
              icon: Icons.event_outlined,
              title: AppStrings.noAppointments,
              subtitle: AppStrings.noAppointmentsSubtitle,
              actionLabel: AppStrings.newAppointment,
              onAction: () {
                final vehicles = context.read<VehicleProvider>().vehicles;
                Navigator.pushNamed(context, AppRoute.createAppointment,
                    arguments: vehicles);
              },
            );
          }

          final sorted = [...appointments]
            ..sort((a, b) => a.fecha.compareTo(b.fecha));

          return RefreshIndicator(
            onRefresh: () => appointmentProvider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                return _AppointmentCard(appointment: sorted[index]);
              },
            ),
          );
        },
        error: (message) => ErrorBanner(
          message: message,
          onRetry: () => appointmentProvider.refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final vehicles = context.read<VehicleProvider>().vehicles;
          Navigator.pushNamed(context, AppRoute.createAppointment,
              arguments: vehicles);
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newAppointment),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.amber;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.grey;
      case AppointmentStatus.noShow:
        return Colors.red;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppStrings.statusPending;
      case AppointmentStatus.confirmed:
        return AppStrings.statusConfirmed;
      case AppointmentStatus.inProgress:
        return 'En Progreso';
      case AppointmentStatus.completed:
        return AppStrings.statusCompleted;
      case AppointmentStatus.cancelled:
        return AppStrings.statusCancelled;
      case AppointmentStatus.noShow:
        return 'No Asistió';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _getStatusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.tipoService.displayName,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    _getStatusText(appointment.status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  dateFormat.format(appointment.fecha),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            if (appointment.observaciones != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                appointment.observaciones!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
