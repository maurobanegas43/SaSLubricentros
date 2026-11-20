import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/common/animated_button.dart';
import '../../constants/app_constants.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _motorController = TextEditingController();
  final _kmController = TextEditingController();
  final _marcaFocus = FocusNode();
  final _modeloFocus = FocusNode();
  final _anioFocus = FocusNode();
  final _motorFocus = FocusNode();
  final _kmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcaFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _motorController.dispose();
    _kmController.dispose();
    _marcaFocus.dispose();
    _modeloFocus.dispose();
    _anioFocus.dispose();
    _motorFocus.dispose();
    _kmFocus.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final vehicleProvider = context.read<VehicleProvider>();

      final success = await vehicleProvider.addVehicle(
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        anio: int.parse(_anioController.text),
        motor: _motorController.text.trim().isEmpty
            ? null
            : _motorController.text.trim(),
        kmActual: int.parse(_kmController.text),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.vehicleCreated),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error when vehicle creation fails
          final errorMessage = vehicleProvider.lastFailure?.message ?? 
              'Error al crear el vehículo. Por favor intenta de nuevo.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleProvider = context.watch<VehicleProvider>();
    final isLoading = vehicleProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addVehicle),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Marca
              TextFormField(
                controller: _marcaController,
                focusNode: _marcaFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.labelMarca,
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Ej: Toyota',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return AppStrings.validationRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Modelo
              TextFormField(
                controller: _modeloController,
                focusNode: _modeloFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.labelModelo,
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Ej: Corolla',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return AppStrings.validationRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Año
              TextFormField(
                controller: _anioController,
                focusNode: _anioFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: AppStrings.labelAnio,
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Ej: 2020',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return AppStrings.validationRequired;
                  final year = int.tryParse(value);
                  if (year == null ||
                      year < 1900 ||
                      year > DateTime.now().year + 1) {
                    return AppStrings.validationInvalidYear;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Motor (optional)
              TextFormField(
                controller: _motorController,
                focusNode: _motorFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: AppStrings.labelMotor,
                  prefixIcon: Icon(Icons.settings_outlined),
                  hintText: 'Ej: 1.8',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Kilometraje
              TextFormField(
                controller: _kmController,
                focusNode: _kmFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: AppStrings.labelKm,
                  prefixIcon: Icon(Icons.speed),
                  hintText: 'Ej: 45000',
                  suffixText: AppStrings.kmSuffix,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return AppStrings.validationRequired;
                  final km = int.tryParse(value);
                  if (km == null || km < 0)
                    return AppStrings.validationInvalidKm;
                  return null;
                },
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AnimatedButton(
                label: AppStrings.addVehicle,
                onPressed: _handleSubmit,
                isLoading: isLoading,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
