import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_router.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/vehicle_card.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_banner.dart';
import '../../constants/app_constants.dart';

class VehiclesListScreen extends StatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  @override
  void initState() {
    super.initState();
    // Load vehicles when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleProvider = context.watch<VehicleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vehiclesTitle),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: vehicleProvider.vehiclesState.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 3,
          itemBuilder: (_, __) => const CardSkeleton(),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_outlined,
              title: AppStrings.noVehicles,
              subtitle: AppStrings.noVehiclesSubtitle,
              actionLabel: AppStrings.addVehicleFab,
              onAction: () => Navigator.pushNamed(context, AppRoute.addVehicle),
            );
          }

          return RefreshIndicator(
            onRefresh: () => vehicleProvider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return VehicleCard(
                  vehicle: vehicle,
                  proximoServiceKm: 50000,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoute.vehicleDetail,
                      arguments: vehicle,
                    );
                  },
                );
              },
            ),
          );
        },
        error: (message) => ErrorBanner(
          message: message,
          onRetry: () => vehicleProvider.refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoute.addVehicle),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addVehicleFab),
      ),
    );
  }
}
