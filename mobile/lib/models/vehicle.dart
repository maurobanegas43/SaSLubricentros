class Vehicle {
  final int id;
  final int userId;
  final String marca;
  final String modelo;
  final int anio;
  final String? motor;
  final int kmActual;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.marca,
    required this.modelo,
    required this.anio,
    this.motor,
    required this.kmActual,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      anio: json['anio'] as int,
      motor: json['motor'] as String?,
      kmActual: json['km_actual'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'motor': motor,
      'km_actual': kmActual,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => '$marca $modelo ($anio)';
}
