import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/vehicle.dart';
import '../../widgets/common/animated_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../constants/app_constants.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  const CreateAppointmentScreen({super.key, required this.vehicles});

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final _serviceTypeFocus = FocusNode();

  Vehicle? _selectedVehicle;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _tipoService = ServiceTypes.all.first;

  @override
  void initState() {
    super.initState();
    if (widget.vehicles.isNotEmpty) {
      _selectedVehicle = widget.vehicles.first;
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _serviceTypeFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _selectedTime = picked);
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate() &&
        _selectedVehicle != null &&
        _selectedDate != null &&
        _selectedTime != null) {
      HapticFeedback.mediumImpact();

      final appointmentProvider = context.read<AppointmentProvider>();
      final fecha = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final success = await appointmentProvider.addAppointment(
        vehicleId: _selectedVehicle!.id,
        fecha: fecha,
        tipoService: _tipoService,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.appointmentCreated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Seleccioná fecha y hora para el turno'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Turno'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
      ),
      body: widget.vehicles.isEmpty
          ? EmptyState(
              icon: Icons.directions_car_outlined,
              title: AppStrings.needVehicle,
              subtitle: AppStrings.needVehicleSubtitle,
            )
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Vehicle Selection
            Text(AppStrings.labelVehicle, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<Vehicle>(
              value: _selectedVehicle,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_outlined),
                hintText: 'Seleccioná un vehículo',
              ),
              items: widget.vehicles.map((vehicle) {
                return DropdownMenuItem(
                  value: vehicle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${vehicle.kmActual} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (vehicle) {
                HapticFeedback.selectionClick();
                setState(() => _selectedVehicle = vehicle);
              },
              validator: (value) =>
                  value == null ? AppStrings.validationSelectVehicle : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Service Type
            Text(AppStrings.labelServiceType,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              value: _tipoService,
              focusNode: _serviceTypeFocus,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.build_outlined),
              ),
              items: ServiceTypes.all.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (tipo) {
                if (tipo != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _tipoService = tipo);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date Selection
            Text(AppStrings.labelDate, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: theme.colorScheme.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? dateFormat.format(_selectedDate!)
                            : AppStrings.selectDate,
                        style: _selectedDate == null
                            ? theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Time Selection
            Text(AppStrings.labelTime, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: theme.colorScheme.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : AppStrings.selectTime,
                        style: _selectedTime == null
                            ? theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Observaciones
            Text(AppStrings.labelObservaciones,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _observacionesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Ej: Revisar frenos',
              ),
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            AnimatedButton(
              label: AppStrings.confirmAppointment,
              onPressed: _handleSubmit,
              icon: Icons.event_available,
            ),
          ],
        ),
      ),
    );
  }
}
