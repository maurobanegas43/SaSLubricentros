import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vehicle.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final List<Vehicle> vehicles;

  const CreateAppointmentScreen({super.key, required this.vehicles});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  
  Vehicle? _selectedVehicle;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _tipoService = 'Cambio de aceite';

  final List<String> _tiposService = [
    'Cambio de aceite',
    'Cambio de filtros',
    'Service completo',
    'Revisión general',
    'Reparación',
  ];

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
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && 
        _selectedVehicle != null && 
        _selectedDate != null && 
        _selectedTime != null) {
      // TODO: Crear turno via API
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turno creado exitosamente')),
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
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.vehicles.isEmpty
          ? _buildNoVehiclesState(context)
          : _buildForm(context),
    );
  }

  Widget _buildNoVehiclesState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Necesitás un vehículo',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Agregá un vehículo antes de sacar un turno',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle Selection
          Text('Vehículo', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<Vehicle>(
            value: _selectedVehicle,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: widget.vehicles.map((vehicle) {
              return DropdownMenuItem(
                value: vehicle,
                child: Text(vehicle.displayName),
              );
            }).toList(),
            onChanged: (vehicle) {
              setState(() => _selectedVehicle = vehicle);
            },
            validator: (value) => value == null ? 'Seleccioná un vehículo' : null,
          ),
          const SizedBox(height: 24),
          
          // Service Type
          Text('Tipo de Service', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _tipoService,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.build_outlined),
            ),
            items: _tiposService.map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Text(tipo),
              );
            }).toList(),
            onChanged: (tipo) {
              if (tipo != null) {
                setState(() => _tipoService = tipo);
              }
            },
          ),
          const SizedBox(height: 24),
          
          // Date Selection
          Text('Fecha', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDate != null
                    ? dateFormat.format(_selectedDate!)
                    : 'Seleccionar fecha',
                style: _selectedDate == null
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Time Selection
          Text('Hora', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.access_time),
              ),
              child: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Seleccionar hora',
                style: _selectedTime == null
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Observaciones
          Text('Observaciones (opcional)', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _observacionesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ej: Revisar frenos',
            ),
          ),
          const SizedBox(height: 32),
          
          // Submit Button
          ElevatedButton(
            onPressed: _handleSubmit,
            child: const Text('Confirmar Turno'),
          ),
        ],
      ),
    );
  }
}
