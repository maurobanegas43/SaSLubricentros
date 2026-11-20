import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../core/app_router.dart';
import '../../models/user.dart';
import '../../models/appointment.dart';
import '../../models/vehicle.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/vehicle_provider.dart';
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
  String? _uploadedImageUrl; // URL de imagen subida al backend
  bool _isSearchingUsers = false;

  @override
  void initState() {
    super.initState();
    // Cargar turnos cuando se abre la pantalla del vehículo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadAppointments();
    });
  }

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
          // Show loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Subiendo imagen...'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Upload image to backend
          final vehicleProvider = context.read<VehicleProvider>();
          final imageUrl = await vehicleProvider.uploadVehicleImage(
            vehicleId: widget.vehicle.id,
            filePath: image.path,
            fileName: image.name,
          );

          if (imageUrl != null && mounted) {
            // Refresh vehicle data to get updated imageUrl from backend
            await context.read<VehicleProvider>().refresh();

            setState(() {
              _vehiclePhotos.add(image);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Foto subida correctamente (${_vehiclePhotos.length}/3)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al subir la foto'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
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
            // Header con imagen de fondo (primera foto) o gradiente
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadii.lg),
                  bottomRight: Radius.circular(AppRadii.lg),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadii.lg),
                  bottomRight: Radius.circular(AppRadii.lg),
                ),
                child: _vehiclePhotos.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Primera foto local como fondo
                          Image.file(
                            File(_vehiclePhotos.first.path),
                            fit: BoxFit.cover,
                          ),
                          // Gradiente para que se lea el texto
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          // Info del auto sobre la foto
                          Positioned(
                            bottom: AppSpacing.lg,
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.vehicle.displayName,
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      const Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.vehicle.motor != null) ...[
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    'Motor ${widget.vehicle.motor}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      shadows: [
                                        const Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : widget.vehicle.hasImage
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Imagen del backend
                              Image.network(
                                widget.vehicle.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.secondary,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.directions_car,
                                        size: 64,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Gradiente para que se lea el texto
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                              // Info del auto sobre la foto
                              Positioned(
                                bottom: AppSpacing.lg,
                                left: AppSpacing.lg,
                                right: AppSpacing.lg,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.vehicle.displayName,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          const Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.vehicle.motor != null) ...[
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        'Motor ${widget.vehicle.motor}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          shadows: [
                                            const Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    widget.vehicle.displayName,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.vehicle.motor != null) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Motor ${widget.vehicle.motor}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

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
                      child: Stack(
                        children: [
                          // Background with vehicle name
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    theme.colorScheme.secondary
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 40,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      widget.vehicle.displayName,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Overlay content
                          Center(
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
                        ],
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
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(_vehiclePhotos[index].path),
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                      // Gradient overlay with vehicle name
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.xs,
                                            horizontal: AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black
                                                    .withValues(alpha: 0.7),
                                                Colors.transparent,
                                              ],
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft:
                                                  Radius.circular(AppRadii.md),
                                              bottomRight:
                                                  Radius.circular(AppRadii.md),
                                            ),
                                          ),
                                          child: Text(
                                            widget.vehicle.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
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

            // Turnos Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Turnos', style: theme.textTheme.headlineMedium),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to create appointment for this vehicle
                      Navigator.pushNamed(
                        context,
                        AppRoute.createAppointment,
                        arguments: widget.vehicle,
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Turno'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Appointments List
            Consumer<AppointmentProvider>(
              builder: (context, appointmentProvider, child) {
                final vehicleAppointments = appointmentProvider.appointments
                    .where((a) => a.vehicleId == widget.vehicle.id)
                    .toList();

                if (appointmentProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (vehicleAppointments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No hay turnos para este vehículo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoute.createAppointment,
                              arguments: widget.vehicle,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Sacar Turno'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicleAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = vehicleAppointments[index];
                    return _AppointmentCard(
                      appointment: appointment,
                      onCancel: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context: context,
                          title: 'Cancelar Turno',
                          message:
                              '¿Querés cancelar el turno del ${DateFormat('dd/MM/yyyy').format(appointment.fecha)}?',
                          confirmLabel: 'Cancelar',
                          cancelLabel: 'No',
                        );
                        if (confirmed == true) {
                          await appointmentProvider
                              .cancelAppointment(appointment.id);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Card widget for displaying appointment in vehicle detail
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Color based on status
    Color statusColor;
    IconData statusIcon;
    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.inProgress:
        statusColor = Colors.purple;
        statusIcon = Icons.autorenew;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case AppointmentStatus.noShow:
        statusColor = Colors.grey;
        statusIcon = Icons.person_off;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.tipoService.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE d/MM/yyyy - HH:mm')
                            .format(appointment.fecha),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (appointment.observaciones != null &&
                appointment.observaciones!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      appointment.observaciones!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Show cancel button only for pending/confirmed appointments
            if (appointment.status == AppointmentStatus.pending ||
                appointment.status == AppointmentStatus.confirmed) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancelar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
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
