# Tasks: Loading

## Fase 1: Componentes Base

### Tarea 1: Crear LoadingSpinner
- [x] Crear componente LoadingSpinner
- [x] Implementar variantes (spinner, dots, bar)
- [x] Agregar props para size y message
- [x] Estilos y animaciones CSS

### Tarea 2: Crear LoadingContext
- [ ] Crear LoadingContext con Provider
- [ ] Implementar showLoading y hideLoading
- [ ] Gestionar estado global de loading
- [ ] Agregar queue para múltiples loadings

### Tarea 3: Crear LoadingOverlay
- [ ] Componente overlay con backdrop
- [ ] Usar Portal para renderizado
- [ ] Integrar con LoadingContext
- [ ] Bloqueo de interacción durante loading

## Fase 2: Hooks y Utilidades

### Tarea 4: Implementar useLoading Hook
- [ ] Hook para loading local
- [ ] Función withLoading para wrappear async
- [ ] Manejo de errores
- [ ] Cleanup automático

### Tarea 5: Crear useLoadingState Hook
- [ ] Hook para estados múltiples (idle, loading, success, error)
- [ ] Transiciones automáticas
- [ ] Reset de estado

## Fase 3: Integración

### Tarea 6: Integrar en App
- [ ] Agregar LoadingProvider en root
- [ ] Configurar LoadingOverlay global
- [ ] Documentar uso

### Tarea 7: Ejemplos de Uso
- [ ] Ejemplo con fetch de datos
- [ ] Ejemplo con formulario
- [ ] Ejemplo con navegación
- [ ] Documentar patrones comunes

## Fase 4: Testing y Refinamiento

### Tarea 8: Tests
- [ ] Tests unitarios para componentes
- [ ] Tests para hooks
- [ ] Tests de integración

### Tarea 9: Accesibilidad
- [ ] Agregar atributos ARIA
- [ ] Anuncios para lectores de pantalla
- [ ] Navegación por teclado

### Tarea 10: Optimización
- [ ] Revisar rendimiento
- [ ] Lazy loading de componentes
- [ ] Optimizar re-renders
