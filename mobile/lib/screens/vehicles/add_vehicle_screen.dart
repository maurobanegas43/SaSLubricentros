import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _motorController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // TODO: Crear vehículo via API
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo agregado exitosamente')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Vehículo'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _marcaController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                prefixIcon: Icon(Icons.directions_car_outlined),
                hintText: 'Ej: Toyota',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresá la marca';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _modeloController,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                prefixIcon: Icon(Icons.directions_car_outlined),
                hintText: 'Ej: Corolla',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresá el modelo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _anioController,
              decoration: const InputDecoration(
                labelText: 'Año',
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'Ej: 2020',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresá el año';
                }
                final year = int.tryParse(value);
                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                  return 'Año inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _motorController,
              decoration: const InputDecoration(
                labelText: 'Motor (opcional)',
                prefixIcon: Icon(Icons.settings_outlined),
                hintText: 'Ej: 1.8',
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _kmController,
              decoration: const InputDecoration(
                labelText: 'Kilometraje Actual',
                prefixIcon: Icon(Icons.speed),
                hintText: 'Ej: 45000',
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresá el kilometraje';
                }
                final km = int.tryParse(value);
                if (km == null || km < 0) {
                  return 'Kilometraje inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Agregar Vehículo'),
            ),
          ],
        ),
      ),
    );
  }
}
