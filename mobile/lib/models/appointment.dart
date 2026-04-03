enum AppointmentStatus { pending, confirmed, completed, cancelled }

class Appointment {
  final int id;
  final int userId;
  final int vehicleId;
  final DateTime fecha;
  final String tipoService;
  final AppointmentStatus status;
  final String? observaciones;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.fecha,
    required this.tipoService,
    required this.status,
    this.observaciones,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      tipoService: json['tipo_service'] as String,
      status: _statusFromString(json['status'] as String),
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static AppointmentStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
    }
  }
}
