# 🔑 Credenciales de Desarrollo

## Modo Desarrollo Activado

La app está en **MODO DESARROLLO** para que puedas ver todas las pantallas sin necesidad de backend.

### Credenciales Pre-cargadas

**Email:** `admin@lubricentros.com`  
**Password:** `Admin123`

### Características del Modo Dev

✅ **Login automático** - Las credenciales ya están pre-cargadas en el formulario  
✅ **Datos de prueba** - 3 vehículos y 3 turnos de ejemplo  
✅ **Sin backend** - Todo funciona localmente  
✅ **Hot reload** - Los cambios se ven instantáneamente  

### Datos de Prueba Incluidos

**Vehículos:**
1. Toyota Corolla 2020 - 45,000 km
2. Ford Focus 2019 - 62,000 km  
3. Volkswagen Gol 2021 - 28,000 km

**Turnos:**
1. Cambio de aceite (Confirmado) - En 3 días
2. Service completo (Pendiente) - En 7 días
3. Cambio de filtros (Completado) - Hace 30 días

### Cómo Usar

1. Abrí la app en el emulador/dispositivo
2. Presiona "Ingresar" (credenciales ya cargadas)
3. Explorá las pantallas:
   - Tab "Vehículos" - Ver lista de autos
   - Tab "Turnos" - Ver turnos programados
   - Botón "+" - Agregar vehículo o turno
   - Tap en un vehículo - Ver detalle

### Desactivar Modo Dev

Para conectar con el backend real, editá:
```dart
// mobile/lib/services/auth_service.dart
static const bool _devMode = false; // Cambiar a false
```

### Hot Reload

Si hiciste cambios y querés verlos:
- Presiona `r` en la terminal de Flutter
- O guarda cualquier archivo Dart (auto hot reload)
