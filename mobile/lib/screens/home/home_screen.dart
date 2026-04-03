import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_router.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/vehicle_card.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../models/appointment.dart';
import '../../constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _tabController.animateTo(index);
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await ConfirmationDialog.show(
      context: context,
      title: AppStrings.logoutTitle,
      message: AppStrings.logoutConfirm,
      confirmLabel: AppStrings.logoutAction,
      cancelLabel: AppStrings.logoutCancel,
      isDestructive: true,
    );

    if (shouldLogout && mounted) {
      HapticFeedback.mediumImpact();
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoute.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $userName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              _selectedIndex == 0
                  ? AppStrings.vehiclesTitle
                  : AppStrings.appointmentsTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: AppStrings.logoutTitle,
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildVehiclesView(context),
          _buildAppointmentsView(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: NavLabels.vehicles,
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: NavLabels.appointments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          if (_selectedIndex == 0) {
            Navigator.pushNamed(context, AppRoute.addVehicle);
          } else {
            final vehicles = context.read<VehicleProvider>().vehicles;
            Navigator.pushNamed(context, AppRoute.createAppointment,
                arguments: vehicles);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_selectedIndex == 0
            ? AppStrings.addVehicleFab
            : AppStrings.newAppointment),
      ),
    );
  }

  Widget _buildVehiclesView(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();

    return vehicleProvider.vehiclesState.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 3,
        itemBuilder: (_, __) => const CardSkeleton(),
      ),
      data: (vehicles) {
        // Build dashboard summary section
        final nextAppointment =
            _getNextAppointment(appointmentProvider.appointments);

        return RefreshIndicator(
          onRefresh: () async => vehicleProvider.refresh(),
          child: CustomScrollView(
            slivers: [
              // Dashboard summary cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick stats row
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.directions_car,
                              label: 'Vehículos',
                              value: '${vehicles.length}',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.event,
                              label: 'Turnos activos',
                              value:
                                  '${_getActiveAppointments(appointmentProvider.appointments)}',
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Next appointment card (if exists)
                      if (nextAppointment != null)
                        _NextAppointmentCard(appointment: nextAppointment),
                    ],
                  ),
                ),
              ),

              // Vehicles list or empty state
              if (vehicles.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: AppStrings.noVehicles,
                    subtitle: AppStrings.noVehiclesSubtitle,
                    actionLabel: AppStrings.addVehicleFab,
                    onAction: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, AppRoute.addVehicle);
                    },
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final vehicle = vehicles[index];
                        return Dismissible(
                          key: ValueKey(vehicle.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.only(right: AppSpacing.md),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return ConfirmationDialog.show(
                              context: context,
                              title: 'Eliminar vehículo',
                              message:
                                  '¿Estás seguro que querés eliminar ${vehicle.displayName}?',
                              confirmLabel: 'Eliminar',
                              isDestructive: true,
                            );
                          },
                          onDismissed: (_) async {
                            HapticFeedback.mediumImpact();
                            await vehicleProvider.deleteVehicle(vehicle.id);
                            if (mounted) {
                              // Use local messenger to avoid context issues across async gaps
                              final messenger = ScaffoldMessenger.of(context);
                              if (messenger.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${vehicle.displayName} eliminado'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          child: VehicleCard(
                            vehicle: vehicle,
                            proximoServiceKm: 50000,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoute.vehicleDetail,
                                arguments: vehicle,
                              );
                            },
                          ),
                        );
                      },
                      childCount: vehicles.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      error: (message) => ErrorBanner(
        message: message,
        onRetry: () => vehicleProvider.refresh(),
      ),
    );
  }

  Widget _buildAppointmentsView(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();

    return appointmentProvider.appointmentsState.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 3,
        itemBuilder: (_, __) => const CardSkeleton(),
      ),
      data: (appointments) {
        return RefreshIndicator(
          onRefresh: () async => appointmentProvider.refresh(),
          child: appointments.isEmpty
              ? EmptyState(
                  icon: Icons.event_outlined,
                  title: AppStrings.noAppointments,
                  subtitle: AppStrings.noAppointmentsSubtitle,
                  actionLabel: AppStrings.newAppointment,
                  onAction: () {
                    HapticFeedback.lightImpact();
                    final vehicles = context.read<VehicleProvider>().vehicles;
                    Navigator.pushNamed(context, AppRoute.createAppointment,
                        arguments: vehicles);
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final sorted = [...appointments]
                      ..sort((a, b) => a.fecha.compareTo(b.fecha));
                    final appointment = sorted[index];
                    return Dismissible(
                      key: ValueKey(appointment.id),
                      direction: appointment.status ==
                                  AppointmentStatus.pending ||
                              appointment.status == AppointmentStatus.confirmed
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                        child: const Icon(Icons.cancel_outlined,
                            color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return ConfirmationDialog.show(
                          context: context,
                          title: 'Cancelar turno',
                          message:
                              '¿Estás seguro que querés cancelar este turno?',
                          confirmLabel: 'Cancelar turno',
                          isDestructive: true,
                        );
                      },
                      onDismissed: (_) async {
                        HapticFeedback.mediumImpact();
                        await appointmentProvider
                            .cancelAppointment(appointment.id);
                        if (mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          if (messenger.mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Turno cancelado'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: _AppointmentCard(appointment: appointment),
                    );
                  },
                ),
        );
      },
      error: (message) => ErrorBanner(
        message: message,
        onRetry: () => appointmentProvider.refresh(),
      ),
    );
  }

  /// Returns the next upcoming appointment (confirmed or pending)
  Appointment? _getNextAppointment(List<Appointment> appointments) {
    final now = DateTime.now();
    final upcoming = appointments
        .where((a) =>
            (a.status == AppointmentStatus.confirmed ||
                a.status == AppointmentStatus.pending) &&
            a.fecha.isAfter(now))
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Returns count of active (confirmed or pending) appointments
  int _getActiveAppointments(List<Appointment> appointments) {
    return appointments
        .where((a) =>
            a.status == AppointmentStatus.confirmed ||
            a.status == AppointmentStatus.pending)
        .length;
  }
}

// ─── Dashboard Summary Widgets ───────────────────────────────────────────────

/// Compact summary card showing a stat with icon and value.
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontSize: 22,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}

/// Card showing the next upcoming appointment.
class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _NextAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE dd/MM - HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Próximo turno',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              appointment.tipoService,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              dateFormat.format(appointment.fecha),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Appointment Card ────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppStrings.statusPending;
      case AppointmentStatus.confirmed:
        return AppStrings.statusConfirmed;
      case AppointmentStatus.completed:
        return AppStrings.statusCompleted;
      case AppointmentStatus.cancelled:
        return AppStrings.statusCancelled;
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
                    appointment.tipoService,
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
