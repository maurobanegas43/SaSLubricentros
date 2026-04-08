class Vehicle {
  final int id;
  final int userId;
  final String? patente;
  final String marca;
  final String modelo;
  final int anio;
  final String? motor;
  final int kmActual;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.userId,
    this.patente,
    required this.marca,
    required this.modelo,
    required this.anio,
    this.motor,
    required this.kmActual,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      patente: json['patente'] as String?,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      anio: json['anio'] as int,
      motor: json['motor'] as String?,
      kmActual: json['km_actual'] as int,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (patente != null) 'patente': patente,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      if (motor != null) 'motor': motor,
      'km_actual': kmActual,
      if (color != null) 'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => '$marca $modelo ($anio)';

  Vehicle copyWith({
    int? id,
    int? userId,
    String? patente,
    String? marca,
    String? modelo,
    int? anio,
    String? motor,
    int? kmActual,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patente: patente ?? this.patente,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      motor: motor ?? this.motor,
      kmActual: kmActual ?? this.kmActual,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
