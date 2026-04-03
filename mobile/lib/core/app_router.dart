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
import '../constants/app_constants.dart';

/// Typed route paths - eliminates string literals throughout the app.
class AppRoute {
  AppRoute._();
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicle-detail';
  static const String addVehicle = '/add-vehicle';
  static const String appointments = '/appointments';
  static const String createAppointment = '/create-appointment';
}

/// Page transition factory for consistent animations.
class AppPageTransitions {
  AppPageTransitions._();

  static PageRouteBuilder<T> slideIn<T>(
    Widget page, {
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration duration = AppDurations.medium,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder<T> fadeIn<T>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: AppDurations.normal,
    );
  }
}

/// Centralized route generator with type-safe argument validation.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.login:
        return AppPageTransitions.fadeIn(
          const LoginScreen(),
          settings: settings,
        );

      case AppRoute.register:
        return AppPageTransitions.slideIn(
          const RegisterScreen(),
          settings: settings,
        );

      case AppRoute.home:
        return AppPageTransitions.fadeIn(
          const HomeScreen(),
          settings: settings,
        );

      case AppRoute.vehicles:
        return AppPageTransitions.slideIn(
          const VehiclesListScreen(),
          settings: settings,
        );

      case AppRoute.vehicleDetail:
        final vehicle = settings.arguments;
        if (vehicle is! Vehicle) {
          return _errorRoute('Se requiere un vehículo', settings);
        }
        return AppPageTransitions.slideIn(
          VehicleDetailScreen(vehicle: vehicle),
          settings: settings,
        );

      case AppRoute.addVehicle:
        return AppPageTransitions.slideIn(
          const AddVehicleScreen(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoute.appointments:
        return AppPageTransitions.slideIn(
          const AppointmentsListScreen(),
          settings: settings,
        );

      case AppRoute.createAppointment:
        final vehicles = settings.arguments;
        if (vehicles is! List<Vehicle>) {
          return _errorRoute('Se requiere lista de vehículos', settings);
        }
        return AppPageTransitions.slideIn(
          CreateAppointmentScreen(vehicles: vehicles),
          settings: settings,
          fullscreenDialog: true,
        );

      default:
        return _errorRoute('${AppStrings.routeNotFound}: ${settings.name}', settings);
    }
  }

  static Route<dynamic> _errorRoute(String message, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.popUntil(_, (route) => route.isFirst),
                    child: const Text(AppStrings.backToHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
