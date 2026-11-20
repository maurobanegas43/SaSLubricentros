enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow
}

enum AppointmentType {
  cambioAceite,
  alineacion,
  mecanicaLuces,
  revisionGeneral,
  otro,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.inProgress:
        return 'in_progress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }

  static AppointmentStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.inProgress:
        return 'En Progreso';
      case AppointmentStatus.completed:
        return 'Completado';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.noShow:
        return 'No Asistió';
    }
  }
}

extension AppointmentTypeExtension on AppointmentType {
  String get value {
    switch (this) {
      case AppointmentType.cambioAceite:
        return 'cambio_aceite';
      case AppointmentType.alineacion:
        return 'alineacion';
      case AppointmentType.mecanicaLuces:
        return 'mecanica_luces';
      case AppointmentType.revisionGeneral:
        return 'revision_general';
      case AppointmentType.otro:
        return 'otro';
    }
  }

  static AppointmentType fromString(String type) {
    switch (type) {
      case 'cambio_aceite':
        return AppointmentType.cambioAceite;
      case 'alineacion':
        return AppointmentType.alineacion;
      case 'mecanica_luces':
        return AppointmentType.mecanicaLuces;
      case 'revision_general':
        return AppointmentType.revisionGeneral;
      case 'otro':
        return AppointmentType.otro;
      default:
        return AppointmentType.otro;
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentType.cambioAceite:
        return 'Cambio de Aceite';
      case AppointmentType.alineacion:
        return 'Alineación';
      case AppointmentType.mecanicaLuces:
        return 'Mecánica y Luces';
      case AppointmentType.revisionGeneral:
        return 'Revisión General';
      case AppointmentType.otro:
        return 'Otro';
    }
  }
}

class Appointment {
  final int id;
  final int userId;
  final int vehicleId;
  final DateTime fecha;
  final DateTime slotEnd;
  final AppointmentType tipoService;
  final AppointmentStatus status;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.fecha,
    required this.slotEnd,
    required this.tipoService,
    required this.status,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      slotEnd: DateTime.parse(json['slot_end'] as String),
      tipoService:
          AppointmentTypeExtension.fromString(json['tipo_service'] as String),
      status: AppointmentStatusExtension.fromString(json['status'] as String),
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'fecha': fecha.toIso8601String(),
      'slot_end': slotEnd.toIso8601String(),
      'tipo_service': tipoService.value,
      'status': status.value,
      if (observaciones != null) 'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayFecha {
    final now = DateTime.now();
    final diff = fecha.difference(now);

    if (diff.isNegative) {
      return 'Pasado';
    } else if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Mañana';
    } else if (diff.inDays < 7) {
      return 'Esta semana';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
