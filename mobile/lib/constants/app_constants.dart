/// Application-wide constants for spacing, durations, and strings.
/// All spacing follows a 4px grid system for visual consistency.

// ─── Spacing (4px grid) ───────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4.0;
  static const double xs  = 8.0;
  static const double sm  = 12.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

// ─── Durations ────────────────────────────────────────────────────────────────
class AppDurations {
  AppDurations._();
  static const Duration fast     = Duration(milliseconds: 150);
  static const Duration normal   = Duration(milliseconds: 250);
  static const Duration medium   = Duration(milliseconds: 350);
  static const Duration slow     = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

// ─── Border Radius ────────────────────────────────────────────────────────────
class AppRadii {
  AppRadii._();
  static const double xs    = 4.0;
  static const double sm    = 8.0;
  static const double md    = 12.0;
  static const double lg    = 16.0;
  static const double xl    = 24.0;
  static const double pill  = 9999.0;
}

// ─── Touch Targets ────────────────────────────────────────────────────────────
class AppTouchTargets {
  AppTouchTargets._();
  static const double minSize = 48.0;
  static const double iconSize = 24.0;
}

// ─── Strings ──────────────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();
  static const String appName = 'Lubricentros';
  static const String devModeLabel = 'MODO DESARROLLO';
  static const String devModeSubtitle = 'Credenciales pre-cargadas';

  // Auth
  static const String loginTitle = 'Ingresá a tu cuenta';
  static const String registerTitle = 'Crear Cuenta';
  static const String registerSubtitle = 'Completá tus datos para comenzar';
  static const String loginButton = 'Ingresar';
  static const String registerButton = 'Crear Cuenta';
  static const String noAccount = '¿No tenés cuenta? Registrate';
  static const String hasAccount = '¿Ya tenés cuenta? Ingresá';
  static const String logoutConfirm = '¿Estás seguro que querés salir?';
  static const String logoutTitle = 'Cerrar sesión';
  static const String logoutCancel = 'Cancelar';
  static const String logoutAction = 'Salir';

  // Vehicles
  static const String vehiclesTitle = 'Mis Vehículos';
  static const String noVehicles = 'No tenés vehículos';
  static const String noVehiclesSubtitle = 'Agregá tu primer auto para comenzar';
  static const String addVehicle = 'Agregar Vehículo';
  static const String addVehicleFab = 'Agregar';
  static const String vehicleDetail = 'Detalle del Vehículo';
  static const String serviceHistory = 'Historial de Servicios';
  static const String noServiceHistory = 'Sin historial de servicios';
  static const String currentKm = 'Kilometraje Actual';
  static const String kmSuffix = 'km';
  static const String nextService = 'Próximo service';

  // Appointments
  static const String appointmentsTitle = 'Mis Turnos';
  static const String noAppointments = 'No tenés turnos';
  static const String noAppointmentsSubtitle = 'Sacá un turno para tu próximo service';
  static const String newAppointment = 'Nuevo Turno';
  static const String confirmAppointment = 'Confirmar Turno';
  static const String createAppointment = 'Nuevo Turno';
  static const String needVehicle = 'Necesitás un vehículo';
  static const String needVehicleSubtitle = 'Agregá un vehículo antes de sacar un turno';
  static const String appointmentCreated = 'Turno creado exitosamente';
  static const String vehicleCreated = 'Vehículo agregado exitosamente';
  static const String selectDate = 'Seleccionar fecha';
  static const String selectTime = 'Seleccionar hora';

  // Status labels
  static const String statusPending = 'Pendiente';
  static const String statusConfirmed = 'Confirmado';
  static const String statusCompleted = 'Completado';
  static const String statusCancelled = 'Cancelado';

  // Form labels
  static const String labelMarca = 'Marca';
  static const String labelModelo = 'Modelo';
  static const String labelAnio = 'Año';
  static const String labelMotor = 'Motor (opcional)';
  static const String labelKm = 'Kilometraje Actual';
  static const String labelVehicle = 'Vehículo';
  static const String labelServiceType = 'Tipo de Service';
  static const String labelDate = 'Fecha';
  static const String labelTime = 'Hora';
  static const String labelObservaciones = 'Observaciones (opcional)';

  // Error messages
  static const String errorConnection = 'Error de conexión';
  static const String errorGeneric = 'Ocurrió un error inesperado';
  static const String errorRetry = 'Reintentar';
  static const String errorNoInternet = 'Sin conexión a internet';
  static const String errorServer = 'Error del servidor';
  static const String routeNotFound = 'Ruta no encontrada';
  static const String backToHome = 'Volver al inicio';

  // Validation
  static const String validationRequired = 'Este campo es obligatorio';
  static const String validationInvalidEmail = 'Email inválido';
  static const String validationMinChars = 'Mínimo %d caracteres';
  static const String validationUppercase = 'Debe tener al menos una mayúscula';
  static const String validationLowercase = 'Debe tener al menos una minúscula';
  static const String validationNumber = 'Debe tener al menos un número';
  static const String validationPasswordsMatch = 'Las contraseñas no coinciden';
  static const String validationInvalidYear = 'Año inválido';
  static const String validationInvalidKm = 'Kilometraje inválido';
  static const String validationSelectVehicle = 'Seleccioná un vehículo';
}

// ─── Service Types ────────────────────────────────────────────────────────────
class ServiceTypes {
  ServiceTypes._();
  static const List<String> all = [
    'Cambio de aceite',
    'Cambio de filtros',
    'Service completo',
    'Revisión general',
    'Reparación',
  ];
}

// ─── Navigation Labels ────────────────────────────────────────────────────────
class NavLabels {
  NavLabels._();
  static const String vehicles = 'Vehículos';
  static const String appointments = 'Turnos';
}
