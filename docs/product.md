# PRODUCT: SaaS Lubricentros (Mobile + Backend)

## CONTEXT
Sistema para digitalizar lubricentros en Argentina.
Incluye app mobile (cliente) + backend en Go (escalable).

---

## CORE IDEA
Gestión de:
- Turnos
- Vehículos
- Servicios (mantenimiento)
- Historial técnico del auto

El producto NO es solo agenda:
Es un sistema de seguimiento del estado del vehículo.

---

## USERS

### CLIENT (Mobile - Flutter)
- Dueño del vehículo
- Usa la app para gestionar autos y services

### ADMIN (Lubricentro)
- Gestiona turnos, servicios y clientes

---

## CLIENT FEATURES

### VEHICLES
- CRUD vehículos
- Campos:
  - marca, modelo, año, motor, km_actual

### APPOINTMENTS
- Crear turno
- Ver turnos
- Estados: pending | confirmed | completed

### SERVICE HISTORY
- Lista de services por vehículo
- Cada service:
  - fecha
  - km
  - tipo_service
  - productos
  - observaciones

### VEHICLE REPORT (KEY FEATURE)
- Historial completo del auto
- Frecuencia de mantenimiento
- Evolución del estado del vehículo

### PRODUCTS INFO
- Ver aceite usado
- Marca y tipo
- Otros insumos

### PRICING / DISCOUNTS
- Precios estimados
- Promociones

---

## ADMIN FEATURES

### DAILY OPERATIONS
- Ver turnos del día
- Datos:
  - cliente
  - vehículo
  - tipo_service
  - hora

### VEHICLE CONTEXT
- Ver historial antes del service
- Últimos trabajos realizados

### SERVICE REGISTRATION
- Registrar service:
  - km
  - tipo_aceite
  - productos
  - observaciones
  - estado_vehiculo

---

## BUSINESS LOGIC

### SERVICE INTERVAL
- mineral: 5000 km
- semi: 7000 km
- sintetico: 10000 km

### NEXT SERVICE
- basado en último km + tipo aceite

### APPOINTMENTS
- no solapamiento

### VEHICLE STATUS
- calculado (no manual):
  - ok
  - maintenance_due
  - critical

---

## TECH STACK

### FRONTEND
- Flutter
- SQLite (cache/offline)

### BACKEND
- Go
- REST API
- preparado para multi-tenant

### DATABASE
- PostgreSQL (principal)

---

## CONSTRAINTS

- Mantener modelo simple (MVP)
- Evitar over-engineering
- Priorizar claridad de datos
- Historial es la fuente de verdad

---

## PRODUCT PRINCIPLES

- Mobile-first
- UX simple
- Datos consistentes > features
- Cada acción debe impactar el historial del vehículo

---

## IMPORTANT

- No desviar el scope
- No agregar features innecesarias
- Mantener coherencia con modelo de vehículo + service
- Pensar como sistema en producción