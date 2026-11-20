import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'core/app_router.dart';
import 'core/auth_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/loading_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/vehicle_service.dart';
import 'services/appointment_service.dart';

final ApiClient _sharedApiClient = ApiClient.instance;
final AuthService _sharedAuthService = AuthService(apiClient: _sharedApiClient);

// Create providers first to allow cross-referencing
final VehicleProvider _vehicleProvider = VehicleProvider(
  vehicleService: VehicleService(apiClient: _sharedApiClient),
);
final AppointmentProvider _appointmentProvider = AppointmentProvider(
  appointmentService: AppointmentService(apiClient: _sharedApiClient),
);
final AuthProvider _authProvider = AuthProvider(
  authService: _sharedAuthService,
);

void main() {
  // Wire up provider references for auto-loading on login
  _authProvider.setVehicleProvider(_vehicleProvider);
  _authProvider.setAppointmentProvider(_appointmentProvider);

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LubricentrosApp());
}

class LubricentrosApp extends StatelessWidget {
  const LubricentrosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _vehicleProvider),
        ChangeNotifierProvider.value(value: _appointmentProvider),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
      ],
      child: MaterialApp(
        title: 'Lubricentros',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // AuthWrapper acts as route guard — shows Login or Home based on auth state
        home: const AuthWrapper(),
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
