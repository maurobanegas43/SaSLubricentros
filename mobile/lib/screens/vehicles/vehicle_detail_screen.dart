import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/empty_state.dart';

class VehicleDetailScreen extends StatelessWidget {
  final dynamic vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vehicleDetail),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        // Consistent back navigation with back arrow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: AppStrings.backToHome,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Editar vehículo
            },
            tooltip: 'Editar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              margin: const EdgeInsets.all(AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Hero animation target — matches VehicleCard icon
                    Hero(
                      tag: 'vehicle-icon-${vehicle.id}',
                      child: Icon(Icons.directions_car,
                          size: 64, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Hero animation target — matches VehicleCard name
                    Hero(
                      tag: 'vehicle-name-${vehicle.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          vehicle.displayName,
                          style: theme.textTheme.displayLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (vehicle.motor != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Motor ${vehicle.motor}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // KM Actual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.speed,
                          color: theme.colorScheme.secondary, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.currentKm,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${NumberFormat('#,###').format(vehicle.kmActual)} ${AppStrings.kmSuffix}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 20,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Historial Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(AppStrings.serviceHistory,
                  style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.md),

            // Empty State for History
            EmptyState(
              icon: Icons.history,
              title: AppStrings.noServiceHistory,
              subtitle: '',
              iconSize: 64,
            ),
          ],
        ),
      ),
    );
  }
}
