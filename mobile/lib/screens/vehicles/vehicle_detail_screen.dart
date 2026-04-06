import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/confirmation_dialog.dart';

class VehicleDetailScreen extends StatefulWidget {
  final dynamic vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _vehiclePhotos = [];
  bool _isSearchingUsers = false;

  Future<void> _addVehiclePhoto() async {
    if (_vehiclePhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 fotos por vehículo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Foto'),
        content: const Text('Seleccioná la fuente de la imagen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Cámara'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Galería'),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _vehiclePhotos.add(image);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Foto agregada (${_vehiclePhotos.length}/3)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar foto: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Eliminar Foto',
      message: '¿Querés eliminar esta foto?',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
    );

    if (confirmed) {
      setState(() {
        _vehiclePhotos.removeAt(index);
      });
    }
  }

  Future<void> _generateReportPDF() async {
    // TODO: Implement PDF generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando reporte PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sellVehicle() async {
    final searchQuery = await showDialog<String>(
      context: context,
      builder: (context) => _SearchUserDialog(),
    );

    if (searchQuery != null && searchQuery.isNotEmpty && mounted) {
      _showSellConfirmation(searchQuery);
    }
  }

  Future<void> _showSellConfirmation(String buyerEmail) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Confirmar Transferencia',
      message: '¿Querés transferir este vehículo a $buyerEmail?',
      confirmLabel: 'Transferir',
      cancelLabel: 'Cancelar',
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehículo transferido a $buyerEmail'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vehicleDetail),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: AppStrings.backToHome,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _generateReportPDF,
            tooltip: 'Generar Reporte PDF',
          ),
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            onPressed: _sellVehicle,
            tooltip: 'Vender/Transferir',
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
                    Hero(
                      tag: 'vehicle-icon-${widget.vehicle.id}',
                      child: Icon(Icons.directions_car,
                          size: 64, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Hero(
                      tag: 'vehicle-name-${widget.vehicle.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          widget.vehicle.displayName,
                          style: theme.textTheme.displayLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (widget.vehicle.motor != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Motor ${widget.vehicle.motor}',
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
                            '${NumberFormat('#,###').format(widget.vehicle.kmActual)} ${AppStrings.kmSuffix}',
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

            // Vehicle Photos Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fotos del Vehículo',
                      style: theme.textTheme.headlineMedium),
                  TextButton.icon(
                    onPressed:
                        _vehiclePhotos.length < 3 ? _addVehiclePhoto : null,
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: Text('Agregar (${_vehiclePhotos.length}/3)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Photos Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _vehiclePhotos.isEmpty
                  ? Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Sin fotos agregadas',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextButton(
                              onPressed: _addVehiclePhoto,
                              child: const Text('Agregar primera foto'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _vehiclePhotos.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.md),
                                  child: Image.file(
                                    File(_vehiclePhotos[index].path),
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                    onPressed: () => _removePhoto(index),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateReportPDF,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Generar Reporte'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sellVehicle,
                      icon: const Icon(Icons.sell_outlined),
                      label: const Text('Vender Auto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
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

// Dialog to search for user to transfer vehicle
class _SearchUserDialog extends StatefulWidget {
  @override
  State<_SearchUserDialog> createState() => _SearchUserDialogState();
}

class _SearchUserDialogState extends State<_SearchUserDialog> {
  final _emailController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar Comprador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ingresá el email o nombre del nuevo propietario'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email o nombre',
              hintText: 'Ej: juan@ejemplo.com',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_emailController.text.contains('@')) {
              Navigator.pop(context, _emailController.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ingresá un email válido'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}
