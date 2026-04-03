import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/vehicles/vehicles_list_screen.dart';
import '../screens/vehicles/vehicle_detail_screen.dart';
import '../screens/vehicles/add_vehicle_screen.dart';
import '../screens/appointments/appointments_list_screen.dart';
import '../screens/appointments/create_appointment_screen.dart';
import '../models/vehicle.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicle-detail';
  static const String addVehicle = '/add-vehicle';
  static const String appointments = '/appointments';
  static const String createAppointment = '/create-appointment';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case vehicles:
        return MaterialPageRoute(builder: (_) => const VehiclesListScreen());
      case vehicleDetail:
        final vehicle = settings.arguments as Vehicle;
        return MaterialPageRoute(
          builder: (_) => VehicleDetailScreen(vehicle: vehicle),
        );
      case addVehicle:
        return MaterialPageRoute(builder: (_) => const AddVehicleScreen());
      case appointments:
        return MaterialPageRoute(builder: (_) => const AppointmentsListScreen());
      case createAppointment:
        final vehicles = settings.arguments as List<Vehicle>;
        return MaterialPageRoute(
          builder: (_) => CreateAppointmentScreen(vehicles: vehicles),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

